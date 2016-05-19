require 'spec_helper'

describe RDF::Sesame::Connection do
  before :each do
    @conn = RDF::Sesame::Connection.new(ENV['SESAME_URL'])
  end

  subject do
    @conn
  end

  after :each do
    @conn.close
  end

  let(:connection_url) do
    URI.parse(ENV['SESAME_URL'] || 'http://localhost:8080/openrdf-sesame').tap do |uri|
      uri.user = uri.password = nil
    end
  end

  it "supports opening a connection" do
    expect(subject).to respond_to(:open)
    expect(subject).not_to be_open
    subject.open
    expect(subject).to be_open
  end

  it "supports closing a connection manually" do
    expect(subject).to respond_to(:close)
    subject.open
    subject.close
    expect(subject).not_to be_open
  end

  it "supports closing a connection automatically" do
    expect(subject).not_to be_open
    subject.open do
      expect(subject).to be_open
    end
    expect(subject).not_to be_open
  end

  it "supports HTTP GET requests" do
    expect(subject).to respond_to(:get)
  end

  it "performs HTTP GET requests" do
    response = subject.get('protocol')
    expect(response).to be_a_kind_of(Net::HTTPSuccess)
    expect(response.body).to be_a(String)
  end

  it "supports HTTP POST requests" do
    expect(subject).to respond_to(:post)
  end

  it "performs HTTP POST requests"

  it "supports HTTP PUT requests" do
    expect(subject).to respond_to(:put)
  end

  it "performs HTTP PUT requests"

  it "supports HTTP DELETE requests" do
    expect(subject).to respond_to(:delete)
  end

  it "performs HTTP DELETE requests"

  it "has a URI representation" do
    expect(subject).to respond_to(:to_uri)
    expect(subject.to_uri).to be_a(URI)
    expect(subject.to_uri).to eq connection_url
  end

  it "has a string representation" do
    expect(subject).to respond_to(:to_s)
    expect(subject.to_s).to eq connection_url.to_s
  end
end
