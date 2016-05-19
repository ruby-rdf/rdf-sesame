require 'spec_helper'

describe 'RDF::Sesame::VERSION' do
  let(:version_file_path) do
    File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'VERSION')
  end

  let(:version) do
    File.read(version_file_path).chomp
  end

  it "should match the VERSION file" do
    expect(RDF::Sesame::VERSION.to_s).to eq version
  end
end
