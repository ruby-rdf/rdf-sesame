require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::Sesame::Connection do
  before :each do
    @url  = RDF::URI.new(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
    @conn = RDF::Sesame::Connection.new(@url)
  end

  it "supports opening a connection" do
    @conn.should respond_to(:open)
    @conn.open?.should be_false
    @conn.open
    @conn.open?.should be_true
  end

  it "supports closing a connection manually" do
    @conn.should respond_to(:close)
    @conn.open?.should be_false
    @conn.open
    @conn.open?.should be_true
    @conn.close
    @conn.open?.should be_false
  end

  it "supports closing a connection automatically" do
    @conn.open?.should be_false
    @conn.open do
      @conn.open?.should be_true
    end
    @conn.open?.should be_false
  end

  it "supports HTTP GET requests" do
    @conn.should respond_to(:get)
  end

  it "performs HTTP GET requests" do
    response = @conn.get("#{@url.path}/protocol")
    response.should be_a_kind_of(Net::HTTPSuccess)
    response.body.should == '4'
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
    @conn.to_uri.to_s.should == RDF::URI.new(@url.to_hash.merge(:path => '')).to_s
  end

  it "has a string representation" do
    @conn.should respond_to(:to_s)
    @conn.to_s.should == RDF::URI.new(@url.to_hash.merge(:path => '')).to_s
  end
end
