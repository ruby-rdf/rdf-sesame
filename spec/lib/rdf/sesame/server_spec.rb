require 'spec_helper'

describe RDF::Sesame::Server do
  let(:connection_url) {
    uri = URI.parse(ENV['SESAME_URL'] || 'http://localhost:8080/openrdf-sesame')
    uri.user = uri.password = nil
    uri
  }

  it "supports URL construction" do
    @server.should respond_to(:url, :uri)
    @server.url.should == connection_url.to_s
    @server.url(:protocol).should == "#{connection_url}/protocol"
    @server.url('repositories/SYSTEM').should == "#{connection_url}/repositories/SYSTEM"
  end

  it "has a URI representation" do
    @server.should respond_to(:to_uri)
    @server.to_uri.should be_a(URI)
    @server.to_uri.should == connection_url
  end

  it "has a string representation" do
    @server.should respond_to(:to_s)
    @server.to_s.should == connection_url.to_s
  end

  it "returns the Sesame connection" do
    @server.connection.should_not be_nil
    @server.connection.should be_instance_of(RDF::Sesame::Connection)
  end

  it "returns the protocol version" do
    @server.should respond_to(:protocol, :protocol_version)
    @server.protocol.should be_a_kind_of(Numeric)
    @server.protocol.should >= 4
  end

  it "returns available repositories" do
    @server.should respond_to(:repositories)
    @server.repositories.should be_a_kind_of(Enumerable)
    @server.repositories.should be_instance_of(Hash)
    @server.repositories.each do |identifier, repository|
      identifier.should be_instance_of(String)
      repository.should be_instance_of(RDF::Sesame::Repository)
    end
  end

  it "indicates whether a repository exists" do
    @server.should respond_to(:has_repository?)
    @server.has_repository?(:SYSTEM).should be_true
    @server.has_repository?(:foobar).should be_false
  end

  it "returns existing repositories" do
    @server.should respond_to(:repository, :[])
    repository = @server.repository(:SYSTEM)
    repository.should_not be_nil
    repository.should be_instance_of(RDF::Sesame::Repository)
  end

  it "does not return nonexistent repositories" do
    lambda { @server.repository(:foobar) }.should_not raise_error
    repository = @server.repository(:foobar)
    repository.should be_nil
  end

  it "supports enumerating repositories" do
    @server.should respond_to(:each_repository, :each)
    @server.each_repository.should be_a(Enumerator)
    @server.each_repository do |repository|
      repository.should be_instance_of(RDF::Sesame::Repository)
    end
  end
end
