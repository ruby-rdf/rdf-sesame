require 'net/http'

module RDF module Sesame
  ##
  # A connection to a Sesame 2.0 HTTP server.
  #
  # @example Connecting to a Sesame server
  #   url  = RDF::URI.new("http://localhost:8080/openrdf-sesame")
  #   conn = RDF::Sesame::Connection.open(url)
  #
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class Connection
    ACCEPT_JSON = {'Accept' => 'application/sparql-results+json'}

    # @return [RDF::URI]
    attr_reader :url

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    # @return [Boolean]
    attr_reader :connected
    alias_method :connected?, :connected
    alias_method :open?,      :connected

    ##
    # Opens a connection to a Sesame server.
    #
    # @param  [RDF::URI]               url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection]
    # @return [Connection]
    def self.open(url, options = {}, &block)
      self.new(url, options) do |conn|
        if conn.open(options) && block_given?
          case block.arity
            when 1 then block.call(conn)
            else conn.instance_eval(&block)
          end
        else
          conn
        end
      end
    end

    ##
    # @param  [RDF::URI]               url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection]
    def initialize(url, options = {}, &block)
      @url, @options = url, options
      @connected = false

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # Opens the connection to the Sesame server.
    #
    # @param  [Hash{Symbol => Object}] options
    # @return [Boolean]
    def open(options = {}, &block)
      if connected?
        true
      else
        @connected = true
        if block_given?
          result = block.call(self)
          close
          result
        end
      end
    end

    alias_method :open!, :open

    ##
    # Closes the connection to the Sesame server.
    #
    # @return [void]
    def close
      if connected?
        # TODO
        @connected = false
      end
    end

    alias_method :close!, :close

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
    # Performs an HTTP GET operation for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{Symbol => Object}] options
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def get(path, options = {}, &block)
      url = case path
        when Symbol then self.url(path.to_s)
        when String then self.url(path)
        else Addressable::URI.parse(path.to_s)
      end

      Net::HTTP.start(url.host, url.port) do |http|
        response = http.get(url.path, options)
        if block_given?
          block.call(response)
        else
          response
        end
      end
    end
  end
end end
