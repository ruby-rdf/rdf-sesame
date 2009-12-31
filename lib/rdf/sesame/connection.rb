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
        if conn.open && block_given?
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
    # @return [Boolean]
    def open
      if connected?
        true
      else
        false # TODO
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
  end
end end
