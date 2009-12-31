require 'rdf/sesame'

describe RDF::Sesame::Server do
  before :each do
    @url    = RDF::URI.new(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
    @server = RDF::Sesame::Server.new(@url)
  end

  it "should support URL construction" do
    @server.url.to_s.should == @url.to_s
    @server.url(:protocol).to_s.should == "#{@url}/protocol"
  end

  it "should return the protocol version" do
    @server.protocol.should be_a_kind_of(Numeric)
    @server.protocol.should >= 4
  end

  it "should return the list of repositories" do
    @server.repositories.should be_a_kind_of(Enumerable)
    @server.repositories.each do |identifier, repository|
      identifier.should be_instance_of(String)
      repository.should be_instance_of(RDF::Sesame::Repository)
    end
  end

  it "should return individual repositories" do
    repository = @server.repository(:SYSTEM)
    repository.should_not be_nil
    repository.should be_instance_of(RDF::Sesame::Repository)
  end
end
