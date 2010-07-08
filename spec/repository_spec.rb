require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/repository'

describe RDF::Sesame::Repository do
  before :each do
    @url    = RDF::URI.new(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
    @server = RDF::Sesame::Server.new(@url)
  end

  context "when created" do
    it "requires exactly one argument" do
      lambda { RDF::Sesame::Repository.new }.should raise_error(ArgumentError)
      lambda { RDF::Sesame::Repository.new(nil, nil) }.should raise_error(ArgumentError)
    end

    it "accepts a string argument" do
      url = "#{@url}/repositories/SYSTEM"
      lambda { RDF::Sesame::Repository.new(url) }.should_not raise_error(ArgumentError)

      db = RDF::Sesame::Repository.new(url)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "accepts a URI argument" do
      url = RDF::URI.new("#{@url}/repositories/SYSTEM")
      lambda { RDF::Sesame::Repository.new(url) }.should_not raise_error(ArgumentError)

      db = RDF::Sesame::Repository.new(url)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "accepts :server and :id" do
      options = {:server => @server, :id => :SYSTEM}
      lambda { RDF::Sesame::Repository.new(options) }.should_not raise_error(ArgumentError)

      db = RDF::Sesame::Repository.new(options)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "rejects :server without :id" do
      options = {:server => @server}
      lambda { RDF::Sesame::Repository.new(options) }.should raise_error(ArgumentError)
    end

    it "rejects :id without :server" do
      options = {:id => :SYSTEM}
      lambda { RDF::Sesame::Repository.new(options) }.should raise_error(ArgumentError)
    end

    it "rejects any other argument" do
      [nil, :SYSTEM, 123, [], {}].each do |value|
        lambda { RDF::Sesame::Repository.new(value) }.should raise_error(ArgumentError)
      end
    end
  end

  context "when used" do
    it "supports URL construction" do
      @server.each_repository do |repository|
        url = "#{@url}/repositories/#{repository.id}"
        repository.should respond_to(:url, :uri)
        repository.url.should be_a_uri
        repository.url.to_s.should == url.to_s
        repository.url(:size).to_s.should == "#{url}/size"
      end
    end

    it "returns the size of each repository" do
      @server.each_repository do |repository|
        repository.size.should be_a_kind_of(Numeric)
      end
    end
  end

  context "when tested" do
    before :each do
      @repository = @server.repository((ENV['SESAME_REPOSITORY'] || :test).to_sym)
      @repository.clear
    end

    after :all do
      @repository.clear
    end

    # @see lib/rdf/spec/repository.rb in rdf-spec
    it_should_behave_like RDF_Repository
  end
end
