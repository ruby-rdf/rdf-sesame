require 'rdf'

module RDF
  ##
  # **`RDF::Sesame`** is a Sesame 2.0 adapter for RDF.rb.
  #
  # Dependencies
  # ------------
  #
  # * [RDF.rb](http://rdf.rubyforge.org/) (>= 0.0.7)
  # * [JSON](http://flori.github.com/json/) (>= 1.2.0)
  #
  # Installation
  # ------------
  #
  # The recommended installation method is via RubyGems. To install the latest
  # official release from Gemcutter, do:
  #
  #     % [sudo] gem install rdf-sesame
  #
  # Documentation
  # -------------
  #
  # * {RDF::Sesame::Connection}
  # * {RDF::Sesame::Repository}
  # * {RDF::Sesame::Server}
  #
  # @example Requiring the `RDF::Sesame` module
  #   require 'rdf/sesame'
  #
  # @see http://rdf.rubyforge.org/
  # @see http://www.openrdf.org/
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  #
  # @author [Arto Bendiken](http://ar.to/)
  module Sesame
    autoload :Connection, 'rdf/sesame/connection'
    autoload :Repository, 'rdf/sesame/repository'
    autoload :Server,     'rdf/sesame/server'
    autoload :VERSION,    'rdf/sesame/version'
  end
end
