#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

GEMSPEC = Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-sesame'
  gem.homepage           = 'http://rdf.rubyforge.org/sesame/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'Sesame 2.0 adapter for RDF.rb.'
  gem.description        = 'RDF.rb plugin providing a Sesame 2.0 storage adapter.'
  gem.rubyforge_project  = 'rdf'

  gem.authors            = ['Arto Bendiken']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS README UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.1'
  gem.requirements               = []
  gem.add_runtime_dependency     'json_pure', '~> 1.4.3'
  gem.add_runtime_dependency     'rdf',       '~> 0.2.0'
  gem.add_development_dependency 'yard' ,     '>= 0.5.8'
  gem.add_development_dependency 'rspec',     '>= 1.3.0'
  gem.add_development_dependency 'rdf-spec',  '~> 0.2.0'
  gem.post_install_message       = nil
end
