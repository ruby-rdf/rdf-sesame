require 'spec_helper'
require 'rdf/spec/repository'

describe RDF::Sesame::Repository do
  before :all do
    @url = @server.url
  end

  context "when created" do
    it "requires exactly one argument" do
      expect { RDF::Sesame::Repository.new }.to raise_error(ArgumentError)
      expect { RDF::Sesame::Repository.new(nil, nil) }.to raise_error(ArgumentError)
    end

    it "accepts a string argument" do
      url = "#{@url}/repositories/SYSTEM"
      expect { RDF::Sesame::Repository.new(url) }.not_to raise_error

      db = RDF::Sesame::Repository.new(url)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "accepts a URI argument" do
      url = RDF::URI("#{@url}/repositories/SYSTEM")
      expect { RDF::Sesame::Repository.new(url) }.not_to raise_error

      db = RDF::Sesame::Repository.new(url)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "accepts :server and :id" do
      options = {:server => @server, :id => :SYSTEM}
      expect { RDF::Sesame::Repository.new(options) }.not_to raise_error

      db = RDF::Sesame::Repository.new(options)
      db.server.to_uri.to_s.should == @url.to_s
    end

    it "rejects :server without :id" do
      options = {:server => @server}
      expect { RDF::Sesame::Repository.new(options) }.to raise_error(ArgumentError)
    end

    it "rejects :id without :server" do
      options = {:id => :SYSTEM}
      expect { RDF::Sesame::Repository.new(options) }.to raise_error(ArgumentError)
    end

    it "rejects any other argument" do
      [nil, :SYSTEM, 123, [], {}].each do |value|
        expect { RDF::Sesame::Repository.new(value) }.to raise_error(ArgumentError)
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
      @repository.clear
    end

    # @see lib/rdf/spec/repository.rb in rdf-spec
    include RDF_Repository
  end
end
