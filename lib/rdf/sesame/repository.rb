module RDF::Sesame
  ##
  # A repository on a Sesame 2.0-compatible HTTP server.
  #
  # Instances of this class represent RDF repositories on Sesame-compatible
  # servers.
  #
  # This class implements the [`RDF::Repository`][RDF::Repository]
  # interface; refer to the relevant RDF.rb API documentation for further
  # usage instructions.
  #
  # [RDF::Repository]: http://rdf.rubyforge.org/RDF/Repository.html
  #
  # @example Opening a Sesame repository (1)
  #   url = "http://localhost:8080/openrdf-sesame/repositories/SYSTEM"
  #   repository = RDF::Sesame::Repository.new(url)
  #
  # @example Opening a Sesame repository (2)
  #   server = RDF::Sesame::Server.new("http://localhost:8080/openrdf-sesame")
  #   repository = RDF::Sesame::Repository.new(:server => server, :id => :SYSTEM)
  #
  # @example Opening a Sesame repository (3)
  #   server = RDF::Sesame::Server.new("http://localhost:8080/openrdf-sesame")
  #   repository = server.repository(:SYSTEM)
  #
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  # @see http://rdf.rubyforge.org/RDF/Repository.html
  class Repository < RDF::Repository
    # @return [RDF::URI]
    attr_reader  :url
    alias_method :uri, :url

    # @return [String]
    attr_reader :id

    # @return [String]
    attr_reader :title

    # @return [Server]
    attr_reader :server

    # @return [String]
    attr_reader :readable

    # @return [String]
    attr_reader :writeble

    class ClientError < StandardError; end
    class MalformedQuery < ClientError; end
    class ServerError < StandardError; end

    ##
    # Initializes this `Repository` instance.
    #
    # @overload initialize(url)
    #   @param  [String, RDF::URI] url
    #   @yield  [repository]
    #   @yieldparam [Repository]
    #
    # @overload initialize(options = {})
    #   @param  [Hash{Symbol => Object}] options
    #   @option options [Server] :server (nil)
    #   @option options [String] :id (nil)
    #   @option options [String] :title (nil)
    #   @yield  [repository]
    #   @yieldparam [Repository]
    #
    def initialize(url_or_options, &block)
      case url_or_options
        when String
          initialize(RDF::URI.new(url_or_options), &block)

        when RDF::URI
          require 'pathname' unless defined?(Pathname)
          @uri     = url_or_options
          @server  = Server.new(RDF::URI.new({
            :scheme   => @uri.scheme,
            :userinfo => @uri.userinfo,
            :host     => @uri.host,
            :port     => @uri.port,
            :path     => Pathname.new(@uri.path).parent.parent.to_s, # + '../..'
          }))
          @options = {}

        when Hash
          raise ArgumentError, "missing options[:server]" unless url_or_options.has_key?(:server)
          raise ArgumentError, "missing options[:id]"     unless url_or_options.has_key?(:id)
          @options = url_or_options.dup
          @server  = @options.delete(:server)
          @id      = @options.delete(:id)
          @uri     = @options.delete(:uri) || server.url("repositories/#{@id}")
          @title   = @options.delete(:title)
          @readable   = @options.delete(:readable)
          @writable   = @options.delete(:writable)

        else
          raise ArgumentError, "expected String, RDF::URI or Hash, but got #{url_or_options.inspect}"
      end

      if block_given?
        case block.arity
          when 1 then yield self
          else instance_eval(&block)
        end
      end
    end

    ##
    # Returns the URL for the given repository-relative `path`.
    #
    # @param  [String, #to_s]        path
    # @param  [Hash, RDF::Statement] query
    # @return [RDF::URI]
    def url(path = nil, query = {})
      url = path ? RDF::URI.new("#{@uri}/#{path}") : @uri.dup # FIXME
      unless query.nil?
        case query
          when RDF::Statement
            writer = RDF::NTriples::Writer.new
            q  = {
              :subj    => writer.format_value(query.subject),
              :pred    => writer.format_value(query.predicate),
              :obj     => writer.format_value(query.object)
            }
            q.merge!(:context => writer.format_value(query.context)) if query.has_context?
            url.query_values = q
          when Hash
            url.query_values = query unless query.empty?
        end
      end
      return url
    end

    alias_method :uri, :url

    ##
    # A mapping of blank node results for this client
    # @private
    def nodes
      @nodes ||= {}
    end

    ##
    # @see RDF::Repository#supports?
    def supports?(feature)
      case feature.to_sym
        when :context then true # statement contexts / named graphs
        else super
      end
    end

    ##
    # @see RDF::Durable#durable?
    def durable?
      true # TODO: would need to query the SYSTEM repository for this information
    end

    ##
    # @see RDF::Countable#empty?
    def empty?
      count.zero?
    end

    ##
    # @see RDF::Countable#count
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e569
    def count
      server.get(url(:size)) do |resp|
        tmp = response(resp)
        begin
          size = tmp.body
          size.to_i
        rescue
          0
        end
      end
    end

    ##
    # @see RDF::Enumerable#has_triple?
    def has_triple?(triple)
      has_statement?(RDF::Statement.from(triple))
    end

    ##
    # @see RDF::Enumerable#has_quad?
    def has_quad?(quad)
      has_statement?(RDF::Statement.new(quad[0], quad[1], quad[2], :context => quad[3]))
    end

    ##
    # @see RDF::Enumerable#has_statement?
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def has_statement?(statement)
      server.get(url(:statements, statement), 'Accept' => 'text/plain') do |resp|
        !response(resp).body.empty?
      end
    end

    ##
    # Returns `true` if `self` contains the given RDF subject term.
    #
    # @param  [RDF::Resource] value
    # @return [Boolean]
    def has_subject?(value)
      !first([value, nil, nil]).nil?
    end

    ##
    # Returns `true` if `self` contains the given RDF predicate term.
    #
    # @param  [RDF::URI] value
    # @return [Boolean]
    def has_predicate?(value)
      !first([nil, value, nil]).nil?
    end

    ##
    # Returns `true` if `self` contains the given RDF object term.
    #
    # @param  [RDF::Term] value
    # @return [Boolean]
    def has_object?(value)
      !first([nil, nil, value]).nil?
    end

    ##
    # @see RDF::Enumerable#each_statement
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def each_statement
      return enum_statement unless block_given?

      [nil, *enum_context].uniq.each do |context|
        query = {}
        query.merge!(:context => RDF::NTriples.serialize(context)) if context
        server.get(url(:statements, query), 'Accept' => 'text/plain') do |resp|
          reader = RDF::NTriples::Reader.new(response(resp).body)
          reader.each_statement do |statement|
            statement.context = context
            yield statement
          end
        end
      end
    end

    alias_method :each, :each_statement

    ##
    # @see RDF::Enumerable#each_context
    def each_context
      return enum_context unless block_given?

      require 'json' unless defined?(::JSON)
      server.get(url(:contexts), Server::ACCEPT_JSON) do |resp|
          json = ::JSON.parse(response(resp).body)
          json['results']['bindings'].map { |binding| binding['contextID'] }.each do |context_id|
            context = case context_id['type'].to_s.to_sym
              when :bnode then RDF::Node.new(context_id['value'])
              when :uri   then RDF::URI.new(context_id['value'])
            end
            yield context if context
          end
      end
    end

    ##
    # Returns all statements of the given query.
    #
    # @private
    # @param  [String, #to_s]        query
    # @param  [String, #to_s]        queryLn
    # @return [RDF::Enumerator]
    def raw_query(query, queryLn = 'sparql')
      case queryLn.to_s
        when 'serql'
          qlang = 'serql'
        else
          qlang = 'sparql'
      end
      params = Addressable::URI.form_encode({ :query => query, :queryLn => qlang }).gsub("+", "%20").to_s
      url = Addressable::URI.parse(self.url)
      unless url.normalize.query.nil?
        url.query = [url.query, params].compact.join('&')
      else
        url.query = [url.query, params].compact.join('?')
      end
      server.get(url, Server::ACCEPT_JSON) do |resp|
        parse_response(response(resp))
      end
    end

  protected

    ##
    # @private
    # @see RDF::Queryable#query
    def query_pattern(pattern)
      writer = RDF::NTriples::Writer.new
      query = {}
      query.merge!(:context => writer.format_value(pattern.context)) if pattern.has_context?
      query.merge!(:subj => writer.format_value(pattern.subject)) unless pattern.subject.is_a?(RDF::Query::Variable) || pattern.subject.nil?
      query.merge!(:pred => writer.format_value(pattern.predicate)) unless pattern.predicate.is_a?(RDF::Query::Variable) || pattern.predicate.nil?
      query.merge!(:obj => writer.format_value(pattern.object)) unless pattern.object.is_a?(RDF::Query::Variable) || pattern.object.nil?
      server.get(url(:statements, query), Server::ACCEPT_NTRIPLES) do |resp|
        reader = RDF::NTriples::Reader.new(response(resp).body)
        reader.each_statement do |statement|
          statement.context = pattern.context
          yield statement
        end
      end
    end

    ##
    # @private
    # @see RDF::Mutable#insert
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statement(statement)
      query = {}
      query.merge!(:context => RDF::NTriples.serialize(statement.context)) if statement.has_context?
      data = RDF::NTriples.serialize(statement)
      server.post(url(:statements, query), data, 'Content-Type' => 'text/plain') do |resp|
        case response(resp).message
          when 'OK'
            true
          else
            false
        end
      end
    end

    ##
    # @private
    # @see RDF::Mutable#delete
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def delete_statement(statement)
      server.delete(url(:statements, statement)) do |resp|
        case response(resp).message
          when 'OK'
            true
          else
            false
        end
      end
    end

    ##
    # @private
    # @see RDF::Mutable#clear
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def clear_statements
      server.delete(url(:statements)) do |resp|
        case response(resp).message
          when 'OK'
            true
          else
            false
        end
      end
    end

  private

    ##
    # Executes a SPARQL query and returns the Net::HTTP::Response of the result.
    #
    # @param [String, #to_s] url
    # @param [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @return [String]
    def response(response, options = {})
      @headers['Accept'] = options[:content_type] if options[:content_type]
      case response
        when Net::HTTPBadRequest # 400 Bad Request
          raise MalformedQuery.new(response.body)
        when Net::HTTPClientError # 4xx
          raise ClientError.new(response.body)
        when Net::HTTPServerError # 5xx
          raise ServerError.new(response.body)
        when Net::HTTPSuccess # 2xx
          response
        else false # FIXME: raise error
      end
    end

    ##
    # @param [Net::HTTPSuccess] response
    # @param [Hash{Symbol => Object}] options
    # @return [Object]
    def parse_response(response, options = {})
      case content_type = options[:content_type] || response.content_type
        when Server::RESULT_BOOL
          response.body == 'true'
        when Server::RESULT_JSON
          self.class.parse_json_bindings(response.body, nodes)
        when Server::RESULT_XML
          self.class.parse_xml_bindings(response.body, nodes)
        else
          parse_rdf_serialization(response, options)
      end
    end

    ##
    # @param [String, Hash] json
    # @return [<RDF::Query::Solutions>]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_json_bindings(json, nodes = {})
      require 'json' unless defined?(::JSON)
      json = JSON.parse(json.to_s) unless json.is_a?(Hash)

      case
        when json['boolean']
          json['boolean']
        when json['results']
          solutions = json['results']['bindings'].map do |row|
            row = row.inject({}) do |cols, (name, value)|
              cols.merge(name.to_sym => parse_json_value(value))
            end
            RDF::Query::Solution.new(row)
          end
          RDF::Query::Solutions.new(solutions)
      end
    end

    ##
    # @param [Hash{String => String}] value
    # @return [RDF::Value]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_json_value(value, nodes = {})
      case value['type'].to_sym
        when :bnode
          nodes[id = value['value']] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value['value'])
        when :literal
          RDF::Literal.new(value['value'], :language => value['xml:lang'])
        when :'typed-literal'
          RDF::Literal.new(value['value'], :datatype => value['datatype'])
        else nil
      end
    end

    ##
    # @param [String, REXML::Element] xml
    # @return [<RDF::Query::Solutions>]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_xml_bindings(xml, nodes = {})
      xml.force_encoding(::Encoding::UTF_8) if xml.respond_to?(:force_encoding)
      require 'rexml/document' unless defined?(::REXML::Document)
      xml = REXML::Document.new(xml).root unless xml.is_a?(REXML::Element)

      case
        when boolean = xml.elements['boolean']
          boolean.text == 'true'
        when results = xml.elements['results']
          solutions = results.elements.map do |result|
            row = {}
            result.elements.each do |binding|
              name = binding.attributes['name'].to_sym
              value = binding.select { |node| node.kind_of?(::REXML::Element) }.first
              row[name] = parse_xml_value(value, nodes)
            end
            RDF::Query::Solution.new(row)
          end
          RDF::Query::Solutions.new(solutions)
      end
    end

    ##
    # @param [REXML::Element] value
    # @return [RDF::Value]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_xml_value(value, nodes = {})
      case value.name.to_sym
        when :bnode
          nodes[id = value.text] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value.text)
        when :literal
          RDF::Literal.new(value.text, {
            :language => value.attributes['xml:lang'],
            :datatype => value.attributes['datatype'],
          })
        else nil
      end
    end

    ##
    # @param [Net::HTTPSuccess] response
    # @param [Hash{Symbol => Object}] options
    # @return [RDF::Enumerable]
    def parse_rdf_serialization(response, options = {})
      options = {:content_type => response.content_type} if options.empty?
      if reader_for = RDF::Reader.for(options)
        reader_for.new(response.body) do |reader|
          reader # FIXME
        end
      end
    end
  end # class Repository
end # module RDF::Sesame
