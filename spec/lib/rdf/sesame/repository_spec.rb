require 'spec_helper'
require 'rdf/ntriples'
#require 'rdf/spec/repository'

describe RDF::Sesame::Repository do
  let(:connection_url) do
    URI.parse(ENV['SESAME_URL'] || 'http://localhost:8080/openrdf-sesame').tap do |uri|
      uri.user = uri.password = nil
    end
  end

  context "when created" do
    it "requires exactly one argument" do
      expect { RDF::Sesame::Repository.new }.to raise_error(ArgumentError)
      expect { RDF::Sesame::Repository.new(nil, nil) }.to raise_error(ArgumentError)
    end

    it "accepts a string argument" do
      url = "#{connection_url}/repositories/SYSTEM"
      expect { RDF::Sesame::Repository.new(url) }.not_to raise_error

      db = RDF::Sesame::Repository.new(url)
      expect(db.server.to_uri.to_s).to eq connection_url.to_s
    end

    it "accepts a URI argument" do
      url = RDF::URI("#{connection_url}/repositories/SYSTEM")
      expect { RDF::Sesame::Repository.new(url) }.not_to raise_error

      db = RDF::Sesame::Repository.new(url)
      expect(db.server.to_uri.to_s).to eq connection_url.to_s
    end

    it "accepts :server and :id" do
      options = {:server => @server, :id => :SYSTEM}
      expect { RDF::Sesame::Repository.new(options) }.not_to raise_error

      db = RDF::Sesame::Repository.new(options)
      expect(db.server.to_uri.to_s).to eq connection_url.to_s
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
        url = "#{connection_url}/repositories/#{repository.id}"
        expect(repository).to respond_to(:url, :uri)
        expect(repository.url).to eq url.to_s
        expect(repository.url(:size).to_s).to eq "#{url}/size"
      end
    end

    it "returns the size of each repository" do
      @server.each_repository do |repository|
        expect(repository.size).to be_a_kind_of(Numeric)
      end
    end
  end

  context "when tested" do
    before :each do
      @repository.clear
    end

    # @see lib/rdf/spec/repository.rb in rdf-spec
    # include RDF_Repository
  end

  describe "#sparql_query" do
    before(:all) do
      path = File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nt')
      @repository.load(path)
    end

    after(:all) do
      @repository.clear
    end

    let(:execution) do
      @repository.sparql_query(query)
    end

    context "with a SELECT query" do
      let(:query) do
        "SELECT ?name WHERE { <http://ar.to/#self> <http://xmlns.com/foaf/0.1/name> ?name }"
      end

      it "returns a RDF::Query::Solutions" do
        expect(execution).to be_kind_of(RDF::Query::Solutions)
        expect(execution).not_to be_empty
      end
    end

    context "with a CONSTRUCT query" do
      let(:query) do
        "CONSTRUCT { <http://ar.to/#self> <http://xmlns.com/foaf/0.1/name> ?name }
        WHERE { <http://ar.to/#self> <http://xmlns.com/foaf/0.1/name> ?name }"
      end

      it "returns a RDF::NTriples::Reader" do
        expect(execution).to be_kind_of(RDF::NTriples::Reader)
        expect(execution).to have_statement(RDF::Statement.new(RDF::URI('http://ar.to/#self'), RDF::URI('http://xmlns.com/foaf/0.1/name'), RDF::Literal('Arto Bendiken')))
      end
    end

    context "with a big query (> #{RDF::Sesame::Repository::MAX_LENGTH_GET_QUERY} bytes)" do
      let(:query) do
        q = "CONSTRUCT { <http://ar.to/#self> <http://xmlns.com/foaf/0.1/name> ?name }
        WHERE { <http://ar.to/#self> <http://xmlns.com/foaf/0.1/name> ?name }"
        RDF::Sesame::Repository::MAX_LENGTH_GET_QUERY.times { q << " " }
        q
      end

      it "returns a RDF::NTriples::Reader" do
        expect(execution).to be_kind_of(RDF::NTriples::Reader)
      end
    end
  end

end
