require 'rdf/sesame'

describe RDF::Sesame::Repository do
  before :each do
    @url    = RDF::URI.new(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
    @server = RDF::Sesame::Server.new(@url)
  end

  context "when created" do
    it "should require exactly one argument" do
      lambda { RDF::Sesame::Repository.new }.should raise_error(ArgumentError)
      lambda { RDF::Sesame::Repository.new(nil, nil) }.should raise_error(ArgumentError)
    end

    it "should accept a string argument" do
      url = "#{@url}/repositories/SYSTEM"
      lambda { RDF::Sesame::Repository.new(url) }.should_not raise_error(ArgumentError)

      db = RDF::Sesame::Repository.new(url)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "should accept a URI argument" do
      url = RDF::URI.new("#{@url}/repositories/SYSTEM")
      lambda { RDF::Sesame::Repository.new(url) }.should_not raise_error(ArgumentError)

      db = RDF::Sesame::Repository.new(url)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "should accept :server and :id" do
      options = {:server => @server, :id => :SYSTEM}
      lambda { RDF::Sesame::Repository.new(options) }.should_not raise_error(ArgumentError)

      db = RDF::Sesame::Repository.new(options)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "should reject :server without :id" do
      options = {:server => @server}
      lambda { RDF::Sesame::Repository.new(options) }.should raise_error(ArgumentError)
    end

    it "should reject :id without :server" do
      options = {:id => :SYSTEM}
      lambda { RDF::Sesame::Repository.new(options) }.should raise_error(ArgumentError)
    end

    it "should reject any other argument" do
      [nil, :SYSTEM, 123, []].each do |value|
        lambda { RDF::Sesame::Repository.new(value) }.should raise_error(ArgumentError)
      end
    end
  end

  context "when used" do
    it "should support URL construction" do
      @server.each_repository do |repository|
        url = "#{@url}/repositories/#{repository.id}"
        repository.should respond_to(:url, :uri)
        repository.url.should be_instance_of(RDF::URI)
        repository.url.to_s.should == url.to_s
        repository.url(:size).to_s.should == "#{url}/size"
      end
    end

    it "should return the size of the repository" do
      @server.each_repository do |repository|
        repository.size.should be_a_kind_of(Numeric)
      end
    end
  end
end
