Sesame 2.0 Adapter for RDF.rb
=============================

This is an [RDF.rb][] plugin that adds support for [Sesame 2.0][]-compatible
RDF repositories accessed using Sesame's [HTTP API][Sesame API].

* <http://github.com/bendiken/rdf-sesame>

Documentation
-------------

* {RDF::Sesame}
  * {RDF::Sesame::Connection}
  * {RDF::Sesame::Repository}
  * {RDF::Sesame::Server}

This adapter implements the [`RDF::Repository`][RDF::Repository] interface;
refer to the relevant RDF.rb API documentation for further usage instructions.

Dependencies
------------

* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.2.2)
* [JSON](http://rubygems.org/gems/json_pure) (>= 1.4.3)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `RDF::Sesame` gem, do:

    % [sudo] gem install rdf-sesame

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/bendiken/rdf-sesame.git

Alternatively, you can download the latest development version as a tarball
as follows:

    % wget http://github.com/bendiken/rdf-sesame/tarball/master

Author
------

* [Arto Bendiken](mailto:arto.bendiken@gmail.com) - <http://ar.to/>

License
-------

`RDF::Sesame` is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.

[RDF.rb]:          http://rdf.rubyforge.org/
[RDF::Repository]: http://rdf.rubyforge.org/RDF/Repository.html
[Sesame 2.0]:      http://www.openrdf.org/
[Sesame API]:      http://www.openrdf.org/doc/sesame2/system/ch08.html
