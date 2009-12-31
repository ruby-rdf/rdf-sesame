require 'net/http'

module RDF module Sesame
  ##
  # A connection to a Sesame 2.0 HTTP server.
  #
  # @example Opening a connection to a Sesame server
  #   url  = RDF::URI.new("http://localhost:8080/openrdf-sesame")
  #   conn = RDF::Sesame::Connection.open(url)
  #
  class Connection
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
    # @param  [RDF::URI, #to_s]        url
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
    # @param  [RDF::URI, #to_s]        url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection]
    def initialize(url, options = {}, &block)
      @url = case url
        when Addressable::URI then url
        else Addressable::URI.parse(url.to_s)
      end

      @options   = options
      @connected = false

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # @return [Boolean]
    def insecure?
      !secure?
    end

    ##
    # @return [Boolean]
    def secure?
      scheme == :https
    end

    ##
    # @return [Symbol]
    def scheme
      url.scheme.to_s.to_sym
    end

    ##
    # @return [String]
    def host
      url.host.to_s
    end

    ##
    # @return [Integer]
    def port
      url.port.to_i
    end

    ##
    # Opens the connection to the Sesame server.
    #
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection] connection
    # @return [void]
    def open(options = {}, &block)
      unless connected?
        # TODO: support persistent connections
        @connected = true
      end

      if block_given?
        result = block.call(self)
        close
        result
      else
        self
      end
    end

    alias_method :open!, :open

    ##
    # Closes the connection to the Sesame server.
    #
    # @return [void]
    def close
      if connected?
        # TODO: support persistent connections
        @connected = false
      end
    end

    alias_method :close!, :close

    ##
    # Performs an HTTP GET request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def get(path, headers = {}, &block)
      Net::HTTP.start(host, port) do |http|
        response = http.get(path.to_s, headers)
        if block_given?
          block.call(response)
        else
          response
        end
      end
    end
  end
end end
