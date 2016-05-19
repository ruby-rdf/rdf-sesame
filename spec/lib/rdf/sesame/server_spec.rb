require 'spec_helper'

describe RDF::Sesame::Server do
  let(:connection_url) do
    URI.parse(ENV['SESAME_URL'] || 'http://localhost:8080/openrdf-sesame').tap do |uri|
      uri.user = uri.password = nil
    end
  end

  subject do
    @server
  end

  it "supports URL construction" do
    expect(subject).to respond_to(:url, :uri)
    expect(subject.url).to eq connection_url.to_s
    expect(subject.url(:protocol)).to eq "#{connection_url}/protocol"
    expect(subject.url('repositories/SYSTEM')).to eq "#{connection_url}/repositories/SYSTEM"
  end

  it "has a URI representation" do
    expect(subject).to respond_to(:to_uri)
    expect(subject.to_uri).to be_a(URI)
    expect(subject.to_uri).to eq connection_url
  end

  it "has a string representation" do
    expect(subject).to respond_to(:to_s)
    expect(subject.to_s).to eq connection_url.to_s
  end

  it "returns the Sesame connection" do
    expect(subject.connection).not_to be_nil
    expect(subject.connection).to be_instance_of(RDF::Sesame::Connection)
  end

  it "returns the protocol version" do
    expect(subject).to respond_to(:protocol, :protocol_version)
    expect(subject.protocol).to be_a_kind_of(Numeric)
    expect(subject.protocol).to be >= 4
  end

  it "returns available repositories" do
    expect(subject).to respond_to(:repositories)
    expect(subject.repositories).to be_a_kind_of(Enumerable)
    expect(subject.repositories).to be_instance_of(Hash)

    subject.repositories.each do |identifier, repository|
      expect(identifier).to be_instance_of(String)
      expect(repository).to be_instance_of(RDF::Sesame::Repository)
    end
  end

  it "indicates whether a repository exists" do
    expect(subject).to respond_to(:has_repository?)
    expect(subject.has_repository?(:SYSTEM)).to be true
    expect(subject.has_repository?(:foobar)).to be false
  end

  it "returns existing repositories" do
    expect(subject).to respond_to(:repository, :[])
    repository = subject.repository(:SYSTEM)
    expect(repository).not_to be_nil
    expect(repository).to be_instance_of(RDF::Sesame::Repository)
  end

  it "does not return nonexistent repositories" do
    expect { subject.repository(:foobar) }.not_to raise_error
    repository = subject.repository(:foobar)
    expect(repository).to be_nil
  end

  it "supports enumerating repositories" do
    expect(subject).to respond_to(:each_repository, :each)
    expect(subject.each_repository).to be_a(Enumerator)

    subject.each_repository do |repository|
      expect(repository).to be_instance_of(RDF::Sesame::Repository)
    end
  end
end
