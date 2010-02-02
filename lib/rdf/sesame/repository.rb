module RDF::Sesame
  ##
  # A repository on a Sesame 2.0-compatible HTTP server.
  #
  # Instances of this class represent RDF repositories on Sesame-compatible
  # servers.
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
  # @see RDF::Sesame
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class Repository < RDF::Repository
    # @return [RDF::URI]
    attr_reader :url
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
          raise ArgumentError.new("missing options[:server]") unless url_or_options.has_key?(:server)
          raise ArgumentError.new("missing options[:id]")     unless url_or_options.has_key?(:id)
          @options = url_or_options.dup
          @server  = @options.delete(:server)
          @id      = @options.delete(:id)
          @uri     = @options.delete(:uri) || server.url("repositories/#{@id}")
          @title   = @options.delete(:title)

        else
          raise ArgumentError.new("wrong argument type #{url_or_options.class} (expected String, RDF::URI or Hash)")
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
              :subj => writer.format_value(query.subject),
              :pred => writer.format_value(query.predicate),
              :obj  => writer.format_value(query.object),
            }
            url.query_values = query
          when Hash then query
            url.query_values = query unless query.empty?
        end
      end
      return url
    end

    alias_method :uri, :url

    ##
    # Returns `true` to indicate that this repository is durable.
    #
    # @return [Boolean]
    def durable?
      true # FIXME
    end

    ##
    # Returns `true` if this repository contains no RDF statements.
    #
    # @return [Boolean]
    def empty?
      count.zero?
    end

    ##
    # Returns the number of RDF statements in this repository.
    #
    # @return [Integer] 
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e569
    def count
      server.get(url(:size)) do |response|
        case response
          when Net::HTTPSuccess
            size = response.body
            size.to_i rescue 0
          else 0
        end
      end
    end

    ##
    # Returns `true` if this repository contains the given RDF statement.
    #
    # @param  [RDF::Statement] statement
    # @return [Boolean]
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def has_statement?(statement)
      server.get(url(:statements, statement), 'Accept' => 'text/plain') do |response|
        case response
          when Net::HTTPSuccess
            reader = RDF::NTriples::Reader.new(response.body)
            reader.include?(statement)
          else false
        end
      end
    end

    ##
    # Enumerates each RDF statement in this repository.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [Enumerator]
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def each_statement(&block)
      server.get(url(:statements), 'Accept' => 'text/plain') do |response|
        case response
          when Net::HTTPSuccess
            reader = RDF::NTriples::Reader.new(response.body)
            reader.each_statement(&block)
        end
      end
    end

    alias_method :each, :each_statement

    ##
    # Inserts the given RDF statement into this repository.
    #
    # @param  [RDF::Statement] statement
    # @return [Boolean]
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statement(statement)
      data = RDF::NTriples::Writer.buffer { |writer| writer << statement } # FIXME for RDF.rb 0.1.0
      server.post(url(:statements), data, 'Content-Type' => 'text/plain') do |response|
        case response
          when Net::HTTPSuccess then true
          else false
        end
      end
    end

    ##
    # Deletes the given RDF statement from this repository.
    #
    # @param  [RDF::Statement] statement
    # @return [Boolean]
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def delete_statement(statement)
      server.delete(url(:statements, statement)) do |response|
        case response
          when Net::HTTPSuccess then true
          else false
        end
      end
    end

    ##
    # Deletes all RDF statements from this repository.
    #
    # @return [Boolean]
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def clear_statements
      server.delete(url(:statements)) do |response|
        case response
          when Net::HTTPSuccess then true
          else false
        end
      end
    end
  end
end
