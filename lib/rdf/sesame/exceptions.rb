module RDF
  class Repository
    class ClientError < StandardError; end
    class MalformedQuery < ClientError; end
    class ServerError < StandardError; end
  end
end
