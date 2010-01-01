module RDF::Sesame
  ##
  # A repository on a Sesame 2.0-compatible HTTP server.
  #
  # Instances of this class represent RDF repositories on Sesame-compatible
  # servers.
  #
  # @example Opening a Sesame repository (1)
  #   url    = "http://localhost:8080/openrdf-sesame/repositories/SYSTEM"
  #   db     = RDF::Sesame::Repository.new(url)
  #
  # @example Opening a Sesame repository (2)
  #   server = RDF::Sesame::Server.new("http://localhost:8080/openrdf-sesame")
  #   db     = RDF::Sesame::Repository.new(:server => server, :id => :SYSTEM)
  #
  # @example Opening a Sesame repository (3)
  #   server = RDF::Sesame::Server.new("http://localhost:8080/openrdf-sesame")
  #   db     = server.repository(:SYSTEM)
  #
  # @see RDF::Sesame
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class Repository < RDF::Repository
    include Enumerable

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
          require 'addressable/uri' unless defined?(Addressable)
          require 'pathname' unless defined?(Pathname)
          @uri     = url_or_options
          @server  = Server.new(RDF::URI.new(Addressable::URI.new({
            :scheme   => @uri.scheme,
            :userinfo => @uri.userinfo,
            :host     => @uri.host,
            :port     => @uri.port,
            :path     => Pathname.new(@uri.path).parent.parent.to_s, # + '../..'
          })))
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
    # @param  [String, #to_s] path
    # @return [RDF::URI]
    def url(path = nil)
      path ? RDF::URI.new("#{@uri}/#{path}") : @uri # FIXME
    end

    alias_method :uri, :url

    protected

      ##
      # Performs an HTTP GET request for the given Sesame repository `path`.
      #
      # @param  [String, #to_s]          path
      # @param  [Hash{String => String}] headers
      # @yield  [response]
      # @yieldparam [Net::HTTPResponse] response
      # @return [Net::HTTPResponse]
      def get(path, headers = {}, &block)
        @server.connection.open do
          @server.connection.get(url(path), headers, &block)
        end
      end

  end
end
