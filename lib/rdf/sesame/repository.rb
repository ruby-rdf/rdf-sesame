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

    # @return [String,Array]
    attr_reader :context

    ##
    # Initializes this `Repository` instance.
    #
    # @overload initialize(url)
    #   @param  [String, URI, RDF::URI] url
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
      options = {}
      case url_or_options
        when String, RDF::URI, URI
          pathname = Pathname.new(url_or_options.to_s)
          @server = Server.new(pathname.parent.parent.to_s)
          @id = pathname.basename.to_s

        when Hash
          raise ArgumentError, "missing options[:server]" unless url_or_options.has_key?(:server)
          raise ArgumentError, "missing options[:id]"     unless url_or_options.has_key?(:id)
          options    = url_or_options.dup
          @server    = options.delete(:server)
          @id        = options.delete(:id)
          @readable  = options.delete(:readable)
          @writable  = options.delete(:writable)

        else
          raise ArgumentError, "expected String, RDF::URI or Hash, but got #{url_or_options.inspect}"
      end

      super(options)
    end

    #
    # Returns the URL for the given server-relative `path`.
    #
    # @example Getting a Sesame server's URL
    #   server.url            #=> "http://localhost:8080/openrdf-sesame"

    # @example Getting a Sesame server's protocol URL
    #   server.url(:protocol) #=> "http://localhost:8080/openrdf-sesame/protocol"
    #
    # @param  [String, #to_s] path
    # @return [String]
    def url(relative_path = nil)
      self.server.url(path(relative_path))
    end

    ##
    # Returns the server-relative path for the given repository-relative `path`.
    #
    # @param  [String, #to_s]        path
    # @param  [Hash, RDF::Statement] query
    # @return [String]
    def path(path = nil, query = {})
      url =  RDF::URI.new(path ? "repositories/#{@id}/#{path}" : "repositories/#{@id}")
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
      return url.to_s
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
      response = server.get(path(:size, statements_options))
      begin
        size = response.body
        size.to_i
      rescue
        0
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
      response = server.get(path(:statements, statement), 'Accept' => 'text/plain')
      !response.body.empty?
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

      # Each context will trigger a query that will be parsed with a NTriples::Reader.
      # This is for performance. Otherwise only one query with TriG::Reader will be
      # necessary

      ['null', *enum_context].uniq.each do |context|
        query = {}
        query.merge!(:context => serialize_context(context)) if context
        response = server.get(path(:statements, query), 'Accept' => 'text/plain')
        RDF::NTriples::Reader.new(response.body).each_statement do |statement|
          statement.context = context
          yield statement
        end
      end
    end

    alias_method :each, :each_statement

    ##
    # @see RDF::Enumerable#each_context
    def each_context
      return enum_context unless block_given?

      require 'json' unless defined?(::JSON)
      response = server.get(path(:contexts), Server::ACCEPT_JSON)
      json = ::JSON.parse(response.body)
      json['results']['bindings'].map { |binding| binding['contextID'] }.each do |context_id|
        context = case context_id['type'].to_s.to_sym
                  when :bnode then RDF::Node.new(context_id['value'])
                  when :uri   then RDF::URI.new(context_id['value'])
                  else
                    nil
                  end
        yield context if context
      end
    end

    # Run a raw SPARQL query.
    #
    # @overload sparql_query(query) {|solution| ... }
    #   @yield solution
    #   @yieldparam [RDF::Query::Solution] solution
    #   @yieldreturn [void]
    #   @return [void]
    #
    # @overload sparql_query(pattern)
    #   @return [Enumerator<RDF::Query::Solution>]
    #
    # @param [String] query The query to run.
    # @param [Hash{Symbol => Object}] options
    #   The query options (see build_query).
    # @return [void]
    #
    # @see #build_query
    def sparql_query(query, options={}, &block)
      raw_query(query, 'sparql', options, &block)
    end

    ##
    # Returns all statements of the given query.
    #
    # @private
    # @param  [String, #to_s]        query
    # @param  [String, #to_s]        queryLn
    # @return [RDF::Enumerator]
    def raw_query(query, queryLn = 'sparql', options={}, &block)
      options = { infer: true }.merge(options)

      response = if query =~ /\b(delete|insert)\b/i
        write_query(query, queryLn, options)
      else
        read_query(query, queryLn, options)
      end
    end

    def read_query(query, queryLn, options)
      if queryLn == 'sparql' and options[:format].nil? and query =~ /\bconstruct\b/i
        options[:format] = Server::ACCEPT_NTRIPLES
      end

      options[:format] = Server::ACCEPT_JSON unless options[:format]

      params = Addressable::URI.form_encode({ :query => query, :queryLn => queryLn, :infer => options[:infer] }).gsub("+", "%20").to_s
      url = Addressable::URI.parse(path)
      unless url.normalize.query.nil?
        url.query = [url.query, params].compact.join('&')
      else
        url.query = [url.query, params].compact.join('?')
      end
      response = server.get(url, options[:format])

      results = parse_response(response)
      if block_given?
        results.each {|s| yield s }
      else
        results
      end
    end

    def write_query(query, queryLn, options)
      parameters = {}
      parameters[:update] = query
      response = server.post(path(:statements), Addressable::URI.form_encode(parameters), 'Content-Type' => 'application/x-www-form-urlencoded')
      response.code == "204"
    end

    # Set a global context that will be used for any statements request
    #
    # @param context the context(s) to use
    def set_context(*context)
      options||={}
      @context = serialize_context(context)
    end

    ##
    # # Clear all statements from the repository.
    # @see RDF::Mutable#clear
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    #
    # @param [Hash] options
    # @option options [String] :subject Match a specific subject
    # @option options [String] :predicate Match a specific predicate
    # @option options [String] :object Match a specific object
    # @option options [String] :context Match a specific graph name.
    # @return [void]
    def clear(options={})
      parameters = {}
      { :subject => :subj, :predicate => :pred, :object => :obj, :context => :context }.each do |option_key, parameter_key|
        value = options[option_key]
        parameters.merge! parameter_key => RDF::NTriples.serialize(RDF::URI.new(value)) if value
      end
      response = server.delete(path(:statements, statements_options.merge(parameters)))
      response.code == "204"
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
      response = server.get(path(:statements, query), Server::ACCEPT_NTRIPLES)
      RDF::NTriples::Reader.new(response.body).each_statement do |statement|
        statement.context = pattern.context
        yield statement
      end
    end

    #--------------------------------------------------------------------
    # @group RDF::Mutable methods

    ##
    # @private
    # @see RDF::Mutable#insert
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statement(statement)
      insert_statements([statement])
    end

    ##
    # @private
    # @see RDF::Mutable#insert
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statements(statements)
      data = statements_to_text_plain(statements)
      response = server.post(path(:statements, statements_options), data, 'Content-Type' => 'text/plain')
      response.code == "204"
    end

    ##
    # @private
    # @see RDF::Mutable#delete
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def delete_statement(statement)
      response = server.delete(path(:statements, statement))
      response.code == "204"
    end

  private

    # Convert a list of statements to a text-plain-compatible text.
    def statements_to_text_plain(statements)
      graph = RDF::Repository.new
      statements.each do |s|
        graph << s
      end
      RDF::NTriples::Writer.dump(graph, nil, :encoding => Encoding::ASCII)
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
          solutions = RDF::Query::Solutions()
          json['results']['bindings'].each do |row|
            row = row.inject({}) do |cols, (name, value)|
              cols.merge(name.to_sym => parse_json_value(value))
            end
            solutions << RDF::Query::Solution.new(row)
          end
          solutions
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
          solutions = RDF::Query::Solutions()
          results.elements.each do |result|
            row = {}
            result.elements.each do |binding|
              name = binding.attributes['name'].to_sym
              value = binding.select { |node| node.kind_of?(::REXML::Element) }.first
              row[name] = parse_xml_value(value, nodes)
            end
            solutions << RDF::Query::Solution.new(row)
          end
          solutions
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

    # @private
    #
    # Serialize the context
    def serialize_context(context)
      context = [context] unless context.is_a?(Enumerable)
      serialization = context.map do |c|
        if c == 'null' or !c
          c
        else
          RDF::NTriples.serialize(RDF::URI.new(c))
        end
      end

      if serialization.size == 1
        serialization.first
      else
        serialization
      end
    end

    # @private
    #
    # Construct the statements options list
    def statements_options
      options = {}
      options[:context] = @context if @context
      options
    end
  end # class Repository
end # module RDF::Sesame
