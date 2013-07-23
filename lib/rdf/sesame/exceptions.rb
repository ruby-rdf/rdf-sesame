module RDF::Sesame
  class ClientError < StandardError; end
  class MalformedQuery < ClientError; end
  class ServerError < StandardError; end
end
