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

        else
          raise ArgumentError, "expected String, RDF::URI or Hash, but got #{url_or_options.inspect}"
      end

      if block_given?
        case block.arity
          when 1 then block.call(self)
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
            query  = {
              :subj    => writer.format_value(query.subject),
              :pred    => writer.format_value(query.predicate),
              :obj     => writer.format_value(query.object),
              :context => query.has_context? ? writer.format_value(query.context) : 'null',
            }
            url.query_values = query
          when Hash
            url.query_values = query unless query.empty?
        end
      end
      return url
    end

    alias_method :uri, :url

    ##
    # @private
    # @see RDF::Repository#supports?
    def supports?(feature)
      case feature.to_sym
        when :context then true # statement contexts / named graphs
        else super
      end
    end

    ##
    # @private
    # @see RDF::Durable#durable?
    def durable?
      true # TODO: would need to query the SYSTEM repository for this information
    end

    ##
    # @private
    # @see RDF::Countable#empty?
    def empty?
      count.zero?
    end

    ##
    # @private
    # @see RDF::Countable#count
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e569
    def count
      server.get(url(:size)) do |response|
        case response
          when Net::HTTPSuccess
            size = response.body
            size.to_i rescue 0
          else -1 # FIXME: raise error
        end
      end
    end

    ##
    # @private
    # @see RDF::Enumerable#has_triple?
    def has_triple?(triple)
      has_statement?(RDF::Statement.from(triple))
    end

    ##
    # @private
    # @see RDF::Enumerable#has_quad?
    def has_quad?(quad)
      has_statement?(RDF::Statement.new(quad[0], quad[1], quad[2], :context => quad[3]))
    end

    ##
    # @private
    # @see RDF::Enumerable#has_statement?
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def has_statement?(statement)
      server.get(url(:statements, statement), 'Accept' => 'text/plain') do |response|
        case response
          when Net::HTTPSuccess
            !response.body.empty?
          else false
        end
      end
    end

    ##
    # @private
    # @see RDF::Enumerable#each_statement
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def each_statement(&block)
      return enum_statement unless block_given?

      [nil, *enum_context].uniq.each do |context|
        ctxt = context ? RDF::NTriples.serialize(context) : 'null'
        server.get(url(:statements, :context => ctxt), 'Accept' => 'text/plain') do |response|
          case response
            when Net::HTTPSuccess
              reader = RDF::NTriples::Reader.new(response.body)
              reader.each_statement do |statement|
                statement.context = context
                block.call(statement)
              end
          end
        end
      end
    end

    alias_method :each, :each_statement

    ##
    # @private
    # @see RDF::Enumerable#each_context
    def each_context(&block)
      return enum_context unless block_given?

      require 'json' unless defined?(::JSON)
      server.get(url(:contexts), Server::ACCEPT_JSON) do |response|
        case response
          when Net::HTTPSuccess
            json = ::JSON.parse(response.body)
            json['results']['bindings'].map { |binding| binding['contextID'] }.each do |context_id|
              context = case context_id['type'].to_s.to_sym
                when :bnode then RDF::Node.new(context_id['value'])
                when :uri   then RDF::URI.new(context_id['value'])
              end
              block.call(context) if context
            end
        end
      end
    end

  protected

    ##
    # @private
    # @see RDF::Queryable#query
    def query_pattern(pattern, &block)
      super # TODO
    end

    ##
    # @private
    # @see RDF::Mutable#insert
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statement(statement)
      ctxt = statement.has_context? ? RDF::NTriples.serialize(statement.context) : 'null'
      data = RDF::NTriples.serialize(statement)
      server.post(url(:statements, :context => ctxt), data, 'Content-Type' => 'text/plain') do |response|
        case response
          when Net::HTTPSuccess then true
          else false
        end
      end
    end

    ##
    # @private
    # @see RDF::Mutable#delete
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def delete_statement(statement)
      server.delete(url(:statements, statement)) do |response|
        case response
          when Net::HTTPSuccess then true
          else false
        end
      end
    end

    ##
    # @private
    # @see RDF::Mutable#clear
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def clear_statements
      server.delete(url(:statements)) do |response|
        case response
          when Net::HTTPSuccess then true
          else false
        end
      end
    end
  end # class Repository
end # module RDF::Sesame
