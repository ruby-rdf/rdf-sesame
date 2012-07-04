require 'spec_helper'

describe 'RDF::Sesame::VERSION' do
  it "should match the VERSION file" do
    version_file_path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'VERSION')
    RDF::Sesame::VERSION.to_s.should == File.read(version_file_path).chomp
  end
end
