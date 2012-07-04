require 'spec_helper'

describe RDF::Sesame::Connection do
  before :all do
    @url = @server.url
  end

  before :each do
    @conn = RDF::Sesame::Connection.new(@url)
  end

  after :each do
    @conn.close
  end

  it "supports opening a connection" do
    @conn.should respond_to(:open)
    @conn.should_not be_open
    @conn.open
    @conn.should be_open
  end

  it "supports closing a connection manually" do
    @conn.should respond_to(:close)
    @conn.open
    @conn.close
    @conn.should_not be_open
  end

  it "supports closing a connection automatically" do
    @conn.should_not be_open
    @conn.open do
      @conn.should be_open
    end
    @conn.should_not be_open
  end

  it "supports HTTP GET requests" do
    @conn.should respond_to(:get)
  end

  it "performs HTTP GET requests" do
    response = @conn.get("#{@url.path}/protocol")
    response.should be_a_kind_of(Net::HTTPSuccess)
    response.body.should be_a String
  end

  it "supports HTTP POST requests" do
    @conn.should respond_to(:post)
  end

  it "performs HTTP POST requests"

  it "supports HTTP PUT requests" do
    @conn.should respond_to(:put)
  end

  it "performs HTTP PUT requests"

  it "supports HTTP DELETE requests" do
    @conn.should respond_to(:delete)
  end

  it "performs HTTP DELETE requests"

  it "has a URI representation" do
    @conn.should respond_to(:to_uri)
    @conn.to_uri.should be_a_uri
    @conn.to_uri.to_s.should == RDF::URI(@url.to_hash.merge(:path => '')).to_s
  end

  it "has a string representation" do
    @conn.should respond_to(:to_s)
    @conn.to_s.should == RDF::URI(@url.to_hash.merge(:path => '')).to_s
  end
end
