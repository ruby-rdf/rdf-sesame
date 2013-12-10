require 'net/http'

module RDF::Sesame
  ##
  # A connection to a Sesame 2.0-compatible HTTP server.
  #
  # Instances of this class represent HTTP connections to a Sesame server,
  # abstracting away the protocol and transport-level details of how the
  # connection is actually established and how requests and responses are
  # implemented and performed.
  #
  # Currently, connections are internally implemented using
  # [`Net::HTTP`](http://ruby-doc.org/core/classes/Net/HTTP.html) from
  # Ruby's standard library, and connections are always transient, i.e. they
  # do not persist from one request to the next and must always be reopened
  # when used. A future improvement would be to support persistent
  # `Keep-Alive` connections.
  #
  # Connections are at any one time in one of the two states of {#close
  # closed} or {#open open} (see {#open?}). You do not generally need to
  # call {#close} explicitly.
  #
  # @example Opening a connection to a Sesame server (1)
  #   url  = URI.parse("http://localhost:8080/openrdf-sesame")
  #   conn = RDF::Sesame::Connection.open(url)
  #   ...
  #   conn.close
  #
  # @example Opening a connection to a Sesame server (2)
  #   url = URI.parse("http://localhost:8080/openrdf-sesame")
  #   RDF::Sesame::Connection.open(url) do |conn|
  #     ...
  #   end
  #
  # @example Performing an HTTP GET on a Sesame server
  #   RDF::Sesame::Connection.open(url) do |conn|
  #     conn.get("/openrdf-sesame/protocol") do |response|
  #       version = response.body.to_i
  #     end
  #   end
  #
  # @see http://ruby-doc.org/core/classes/Net/HTTP.html
  class Connection
    # @return [String]
    attr_reader :user

    # @return [String]
    attr_reader :pass

    # @return [String]
    attr_reader :proxy_host

    # @return [Number]
    attr_reader :proxy_port

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    # @return [Hash{String => String}]
    attr_reader :headers

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
            when 1 then yield conn
            else conn.instance_eval(&block)
          end
        else
          conn
        end
      end
    end

    ##
    # Initializes this connection.
    #
    # @param  [RDF::URI, #to_s]        url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection]
    def initialize(url = nil, options = {}, &block)
      url ||= "http://localhost:8080/openrdf-sesame"
      parsed = URI.parse(url.to_s)

      @user = options.delete(:user) || parsed.user || nil
      @pass = options.delete(:pass) || parsed.password || nil

      # Preserve only those URI components that we actually require for
      # establishing a connection to the HTTP server in question:
      parsed.user = parsed.password = nil
      @url = parsed

      @proxy_host = options.delete(:proxy_host) || nil
      @proxy_port = options.delete(:proxy_port) || nil
      @headers   = options.delete(:headers) || {}
      @options   = options
      @connected = false

      if block_given?
        case block.arity
          when 1 then yield self
          else instance_eval(&block)
        end
      end
    end

    ##
    # Returns `true` unless this is an HTTPS connection.
    #
    # @return [Boolean]
    def insecure?
      !secure?
    end

    ##
    # Returns `true` if this is an HTTPS connection.
    #
    # @return [Boolean]
    def secure?
      scheme == :https
    end

    ##
    # Returns `:http` or `:https` to indicate whether this is an HTTP or
    # HTTPS connection, respectively.
    #
    # @return [Symbol]
    def scheme
      @url.scheme.to_s.to_sym
    end

    ##
    # Returns `true` if there is user name and password information for this
    # connection.
    #
    # @return [Boolean]
    def userinfo?
      !@url.userinfo.nil?
    end

    ##
    # Returns any user name and password information for this connection.
    #
    # @return [String] "username:password"
    def userinfo
      @url.userinfo
    end

    ##
    # Returns `true` if there is user name information for this connection.
    #
    # @return [Boolean]
    def user?
      !user.nil?
    end

    ##
    # Returns `true` if there is password information for this connection.
    #
    # @return [Boolean]
    def password?
      !password.nil?
    end

    ##
    # Returns the host name for this connection.
    #
    # @return [String]
    def host
      @url.host.to_s
    end

    alias_method :hostname, :host

    ##
    # Returns `true` if the port number for this connection differs from the
    # standard HTTP or HTTPS port number (80 and 443, respectively).
    #
    # @return [Boolean]
    def port?
      !@url.port.nil? && @url.port != (insecure? ? 80 : 443)
    end

    ##
    # Returns the port number for this connection.
    #
    # @return [Integer]
    def port
      @url.port
    end

    ##
    # Returns the URI representation of this connection.
    #
    # @return [RDF::URI]
    def to_uri
      @url
    end

    ##
    # Returns a string representation of this connection.
    #
    # @return [String]
    def to_s
      @url.to_s
    end

    ##
    # Returns a developer-friendly representation of this connection.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, object_id, to_s)
    end

    ##
    # Establishes the connection to the Sesame server.
    #
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection] connection
    # @raise  [TimeoutError] if the connection could not be opened
    # @return [Connection]
    def open(options = {})
      unless connected?
        # TODO: support persistent connections
        @connected = true
      end

      if block_given?
        result = yield self
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
    # You do not generally need to call {#close} explicitly.
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
    def get(path, headers = {})
      Net::HTTP::Proxy(@proxy_host, @proxy_port).start(host, port, :use_ssl => self.secure?) do |http|
        request = Net::HTTP::Get.new(url(path.to_s), @headers.merge(headers))
        request.basic_auth @user, @pass unless @user.nil? || @pass.nil?
        response = http.request(request)
        if block_given?
          yield response
        else
          response
        end
      end
    end

    ##
    # Performs an HTTP POST request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [String, #to_s]          data
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def post(path, data, headers = {})
     Net::HTTP::Proxy(@proxy_host, @proxy_port).start(host, port, :use_ssl => self.secure?) do |http|
        request = Net::HTTP::Post.new(url(path.to_s), @headers.merge(headers))
        request.body = data.to_s
        request.basic_auth @user, @pass unless @user.nil? || @pass.nil?
        response = http.request(request)
        if block_given?
          yield response
        else
          response
        end
      end
    end

    ##
    # Performs an HTTP PUT request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def put(path, data, headers = {})
      Net::HTTP::Proxy(@proxy_host, @proxy_port).start(host, port, :use_ssl => self.secure?) do |http|
        request = Net::HTTP::Put.new(url(path.to_s), @headers.merge(headers))
        request.body = data.to_s
        request.basic_auth @user, @pass unless @user.nil? || @pass.nil?
        response = http.request(request)
        http.request(request) do |response|
          if block_given?
            yield response
          else
            response
          end
        end
      end
    end

    ##
    # Performs an HTTP DELETE request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def delete(path, headers = {})
      Net::HTTP::Proxy(@proxy_host, @proxy_port).start(host, port, :use_ssl => self.secure?) do |http|
        request = Net::HTTP::Delete.new(url(path.to_s), @headers.merge(headers))
        request.basic_auth @user, @pass unless @user.nil? || @pass.nil?
        response = http.request(request)
        if block_given?
          yield response
        else
          response
        end
      end
    end

    def url(path)
      if path
        "#{@url}/#{path}"
      else
        @url.to_s
      end
    end
  end # class Connection
end # module RDF::Sesame
