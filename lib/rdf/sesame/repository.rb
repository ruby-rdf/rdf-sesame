module RDF module Sesame
  ##
  # A repository on a Sesame 2.0 HTTP server.
  #
  # @example Connecting to a repository
  #   url = RDF::URI.new("http://localhost:8080/openrdf-sesame/repositories/")
  #   db  = RDF::Sesame::Repository.new(:url => url)
  #
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class Repository < RDF::Repository
    alias_method :url, :uri

    # @return [Connection]
    attr_reader :connection

    ##
    # @param  [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :url (nil)
    # @yield  [repository]
    # @yieldparam [Repository]
    def initialize(options = {}, &block)
      @title   = options.delete(:title) if options.has_key?(:title)
      @uri     = options.delete(:url) || options.delete(:uri)
      @options = options

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end
  end
end end
