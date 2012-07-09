require 'rdf/sesame'
require 'rdf/spec'

RSpec.configure do |config|
  config.before(:all) do
    setup
  end

  config.after(:all) do
    teardown
  end
end

def setup
  @server = RDF::Sesame::Server.new RDF::URI(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
  repository_name = ENV['SESAME_REPOSITORY'] || "rdf-sesame-test"
  @repository = @server.repository(repository_name)
  unless @repository
    raise "You must manually create '#{repository_name}' repository at your Sesame server in order to run tests"
  end
end

def teardown
  @server && @server.connection.close
end
