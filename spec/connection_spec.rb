require 'rdf/sesame'

describe RDF::Sesame::Connection do
  before :each do
    @url  = RDF::URI.new(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
    @conn = RDF::Sesame::Connection.open(@url)
  end

  it "should support URL construction" do
    @conn.url.to_s.should == @url.to_s
    @conn.url(:protocol).to_s.should == "#{@url}/protocol"
  end

  it "should return the protocol version" do
    @conn.protocol.should be_a_kind_of(Numeric)
    @conn.protocol.should >= 4
  end

  it "should return the list of repositories" do
    @conn.repositories.should be_a_kind_of(Enumerable)
    @conn.repositories.each do |identifier, repository|
      identifier.should be_instance_of(String)
      repository.should be_instance_of(RDF::Sesame::Repository)
    end
  end

  it "should return individual repositories" do
    repository = @conn.repository(:SYSTEM)
    repository.should_not be_nil
    repository.should be_instance_of(RDF::Sesame::Repository)
  end
end
