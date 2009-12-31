module RDF module Sesame
  ##
  # A Sesame 2.0 HTTP server.
  #
  # @example Connecting to a Sesame server
  #   url    = RDF::URI.new("http://localhost:8080/openrdf-sesame")
  #   server = RDF::Sesame::Server.new(url)
  #
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class Server
    ACCEPT_JSON = {'Accept' => 'application/sparql-results+json'}

    # @return [RDF::URI]
    attr_reader :url

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    # @return [Connection]
    attr_reader :connection

    ##
    # @param  [RDF::URI]               url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Server]
    def initialize(url, options = {}, &block)
      @url = case url
        when Addressable::URI then url
        else Addressable::URI.parse(url.to_s)
      end

      @options = options

      @connection = Connection.new(Addressable::URI.new({
        :scheme => @url.scheme,
        :host   => @url.host,
        :port   => @url.port,
      }))

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # Returns the absolute `URI` for the given server-relative `path`.
    #
    # @param  [#to_s] path
    # @return [URI]
    def url(path = nil)
      Addressable::URI.parse(path ? "#{@url}/#{path}" : @url.to_s) # FIXME
    end

    alias_method :uri, :url

    ##
    # Returns the Sesame server's protocol version.
    #
    # @example Retrieving the protocol version
    #   conn.protocol #=> 4
    #
    # @return [Integer]
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e180
    def protocol
      get(:protocol) do |response|
        case response
          when Net::HTTPSuccess
            version = response.body
            version.to_i rescue 0
          else 0
        end
      end
    end

    alias_method :protocol_version, :protocol

    ##
    # Returns a repository on the Sesame server.
    #
    # @param  [String] id
    # @return [Repository]
    # @see    #repositories
    def repository(id)
      repositories[id.to_s]
    end

    ##
    # Returns the list of repositories on the Sesame server.
    #
    # @return [Hash{String => Repository}]
    # @see    #repository
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e204
    def repositories
      require 'json' unless defined?(JSON)

      get(:repositories, ACCEPT_JSON) do |response|
        case response
          when Net::HTTPSuccess
            json = JSON.parse(response.body)
            json['results']['bindings'].inject({}) do |repositories, binding|
              repository = Repository.new({
                :uri      => RDF::URI.new(binding['uri']['value']),
                :id       => binding['id']['value'],
                :title    => binding['title']['value'],
                :readable => binding['readable']['value'] == 'true',
                :writable => binding['writable']['value'] == 'true',
              })
              repositories.merge({repository.id => repository})
            end
          else [] # FIXME
        end
      end
    end

    protected

      ##
      # @param  [String, #to_s]          path
      # @param  [Hash{String => String}] headers
      # @yield  [response]
      # @yieldparam [Net::HTTPResponse] response
      # @return [Net::HTTPResponse]
      def get(path, headers = {}, &block)
        @connection.open do
          @connection.get(url(path), headers, &block)
        end
      end

  end
end end
