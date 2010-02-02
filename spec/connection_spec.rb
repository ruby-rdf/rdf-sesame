require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::Sesame::Connection do
  before :each do
    @url  = RDF::URI.new(ENV['SESAME_URL'] || "http://localhost:8080/openrdf-sesame")
    @conn = RDF::Sesame::Connection.new(@url)
  end

  it "should support opening a connection" do
    @conn.should respond_to(:open)
    @conn.open?.should be_false
    @conn.open
    @conn.open?.should be_true
  end

  it "should support closing a connection manually" do
    @conn.should respond_to(:close)
    @conn.open?.should be_false
    @conn.open
    @conn.open?.should be_true
    @conn.close
    @conn.open?.should be_false
  end

  it "should support closing a connection automatically" do
    @conn.open?.should be_false
    @conn.open do
      @conn.open?.should be_true
    end
    @conn.open?.should be_false
  end

  it "should support HTTP GET requests" do
    @conn.should respond_to(:get)
  end

  it "should perform HTTP GET requests" do
    response = @conn.get("#{@url.path}/protocol")
    response.should be_a_kind_of(Net::HTTPSuccess)
    response.body.should == "4"
  end

  it "should support HTTP POST requests" do
    @conn.should respond_to(:post)
  end

  it "should support HTTP PUT requests" do
    @conn.should respond_to(:put)
  end

  it "should support HTTP DELETE requests" do
    @conn.should respond_to(:delete)
  end

  it "should have a URI representation" do
    @conn.to_uri.should be_a_kind_of(RDF::URI)
    @conn.to_uri.to_s.should == "http://localhost:8080"
  end

  it "should have a string representation" do
    @conn.to_s.should == "http://localhost:8080"
  end
end
