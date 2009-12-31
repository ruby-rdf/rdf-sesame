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
    def open(options = {})
      if connected?
        true
      else
        # TODO
        @connected = true
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
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e180
    def protocol
      version = Net::HTTP.get(url(:protocol))
      version ? version.to_i : version
    end

    alias_method :protocol_version, :protocol

    ##
    # Returns the absolute `URI` for the given server-relative `path`.
    #
    # @param  [#to_s] path
    # @return [URI]
    def url(path = nil)
      ::URI.parse(path ? "#{@url}/#{path}" : @url.to_s) # FIXME
    end

    alias_method :uri, :url
  end
end end
