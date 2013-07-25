module RDF::Sesame
  ##
  # A server endpoint compatible with the Sesame 2.0 HTTP protocol.
  #
  # Instances of this class represent Sesame-compatible servers that contain
  # one or more readable and/or writable RDF {Repository repositories}.
  #
  # @example Connecting to a Sesame server
  #   url    = RDF::URI("http://localhost:8080/openrdf-sesame")
  #   server = RDF::Sesame::Server.new(url)
  #
  # @example Connecting to a Sesame server using Basic Auth & local proxy
  #   url    = RDF::URI("http://host:port")
  #   server = RDF::Sesame::Server.new(url, {:user=> 'username', :pass => 'password',
  #       :proxy_host => 'localhost', :proxy_port => 8888})
  #   repo = server.repositories['repositoryname']
  #
  # @example Retrieving the server's protocol version
  #   server.protocol                 #=> 4
  #
  # @example Iterating over available RDF repositories
  #   server.each_repository do |repository|
  #     puts repository.inspect
  #   end
  #
  # @example Finding all readable, non-empty RDF repositories
  #   server.find_all do |repository|
  #     repository.readable? && !repository.empty?
  #   end
  #
  # @example Checking if any RDF repositories are writable
  #   server.any? { |repository| repository.writable? }
  #
  # @example Checking if a specific RDF repository exists on the server
  #   server.has_repository?(:SYSTEM) #=> true
  #   server.has_repository?(:foobar) #=> false
  #
  # @example Obtaining a specific RDF repository
  #   server.repository(:SYSTEM)      #=> RDF::Sesame::Repository(SYSTEM)
  #   server[:SYSTEM]                 #=> RDF::Sesame::Repository(SYSTEM)
  #
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class Server
    include Enumerable

    ACCEPT_JSON = {'Accept' => 'application/sparql-results+json'}.freeze
    ACCEPT_NTRIPLES = {'Accept' => 'text/plain'}.freeze
    ACCEPT_XML  = {'Accept' => 'application/sparql-results+xml'}.freeze
    ACCEPT_BOOL = {'Accept' => 'text/boolean'}.freeze
    ACCEPT_XML_PURE =  {'Accept' => 'application/rdf+xml' }.freeze
    ACCEPT_TURTLE =  {'Accept' => 'application/x-turtle'}.freeze
    ACCEPT_N3 =  {'Accept' => 'text/rdf+n3'}.freeze
    ACCEPT_TRIX =  {'Accept' => 'application/trix'}.freeze
    ACCEPT_TRIG =  {'Accept' => 'application/x-trig'}.freeze
    ACCEPT_BINARY =  {'Accept' => 'application/x-binary-rdf'}.freeze
    ACCEPT_BINARY_TABLE = {'Accept' => 'application/x-binary-rdf-results-table'}.freeze

    RESULT_BOOL = 'text/boolean'.freeze
    RESULT_JSON = 'application/sparql-results+json'.freeze
    RESULT_XML = 'application/sparql-results+xml'.freeze

    # @return [RDF::URI]
    attr_reader :url

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    # @return [Connection]
    attr_reader :connection

    ##
    # Initializes this `Server` instance.
    #
    # @param  [RDF::URI]               url
    # @param  [Hash{Symbol => Object}] options
    # @option options [Connection] :connection (nil)
    # @yield  [connection]
    # @yieldparam [Server]
    def initialize(url, options = {}, &block)
      require 'addressable/uri' unless defined?(Addressable)

      @url = case url
        when Addressable::URI then url
        else Addressable::URI.parse(url.to_s)
      end
      @url = RDF::URI.new(@url)

      user = options.delete(:user) || nil
      pass = options.delete(:pass) || nil
      ssl_port = options.delete(:ssl_port) || nil

      @proxy_host = options.delete(:proxy_host) || nil
      @proxy_port = options.delete(:proxy_port) || nil

      @connection = options.delete(:connection) || Connection.new(@url , {:ssl_port => ssl_port, :user => user, :pass => pass, :headers => {}, :proxy_host => @proxy_host, :proxy_port => @proxy_port})

      @options    = options

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # Returns the URL for the given server-relative `path`.
    #
    # @example Getting a Sesame server's URL
    #   server.url            #=> RDF::URI("http://localhost:8080/openrdf-sesame")
    #
    # @example Getting a Sesame server's protocol URL
    #   server.url(:protocol) #=> RDF::URI("http://localhost:8080/openrdf-sesame/protocol")
    #
    # @param  [String, #to_s] path
    # @return [RDF::URI]
    def url(path = nil)
      path ? RDF::URI.new("#{@url}/#{path}") : @url # FIXME
    end

    alias_method :uri, :url

    ##
    # Returns the URL of this server.
    #
    # @return [RDF::URI]
    def to_uri
      url
    end

    ##
    # Returns the URL of this server as a string.
    #
    # @return [String]
    def to_s
      url.to_s
    end

    ##
    # Returns a developer-friendly representation of this instance.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, object_id, to_s)
    end

    ##
    # Returns the Sesame server's protocol version.
    #
    # @example Retrieving the protocol version
    #   server.protocol #=> 4
    #
    # @return [Integer]
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e180
    def protocol
      response = get(url(:protocol))
      version = response.body
      version.to_i rescue 0
    end

    alias_method :protocol_version, :protocol

    ##
    # Enumerates over each repository on this Sesame server.
    #
    # @yield  [repository]
    # @yieldparam [Repository] repository
    # @return [Enumerator]
    # @see    #repository
    # @see    #repositories
    def each_repository(&block)
      repositories.values.each(&block)
    end

    alias_method :each, :each_repository

    ##
    # Returns `true` if this server has a repository identified by `id`.
    #
    # @param  [String] id
    # @return [Boolean]
    def has_repository?(id)
      repositories.has_key?(id.to_s)
    end

    ##
    # Returns a repository on this Sesame server.
    #
    # @param  [String] id
    # @return [Repository]
    # @see    #repositories
    # @see    #each_repository
    def repository(id)
      repositories[id.to_s]
    end

    alias_method :[], :repository

    ##
    # Returns all repositories on this Sesame server.
    #
    # @return [Hash{String => Repository}]
    # @see    #repository
    # @see    #each_repository
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e204
    def repositories
      require 'json' unless defined?(::JSON)

      response = get(url(:repositories), ACCEPT_JSON)

      json = ::JSON.parse(response.body)
      json['results']['bindings'].inject({}) do |repositories, binding|
        repository_id = binding['id']['value']
        repository = Repository.new(:server   => self,
                                    :uri      => RDF::URI.new(binding['uri']['value']),
                                    :id       => repository_id,
                                    :title    => binding['title']['value'],
                                    :readable => binding['readable']['value'].to_s == 'true',
                                    :writable => binding['writable']['value'].to_s == 'true')
        repositories.merge!(repository_id => repository)
      end
    end

    def get(path, headers = {})
      self.connection.open do
        process_response self.connection.get(path, headers)
      end
    end

    def post(path, data, headers = {})
      self.connection.open do
        process_response self.connection.post(path, data, headers)
      end
    end

    def put(path, data, headers = {})
      self.connection.open do
        process_response self.connection.put(path, data, headers)
      end
    end

    def delete(path, headers = {})
      self.connection.open do
        process_response self.connection.delete(path, headers)
      end
    end

    ##
    # Executes a SPARQL query and returns the Net::HTTP::Response of the result.
    #
    # @param [String, #to_s] url
    # @param [Hash{Symbol => Object}] options
    # @option options [String] :content_type
    # @return [String]
    def process_response(response, options = {})
      @headers['Accept'] = options[:content_type] if options[:content_type]
      if response.is_a?(Net::HTTPSuccess)
        response
      else
        case response
        when Net::HTTPBadRequest # 400 Bad Request
          raise MalformedQuery.new(response.body)
        when Net::HTTPClientError # 4xx
          raise ClientError.new(response.body)
        when Net::HTTPServerError # 5xx
          raise ServerError.new(response.body)
        else
          raise ServerError.new(response.body)
        end
      end
    end

  end # class Server
end # module RDF::Sesame
