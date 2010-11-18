Sesame 2.0 Adapter for RDF.rb
=============================

This is an [RDF.rb][] plugin that adds support for [Sesame 2.0][]-compatible
RDF repositories accessed using Sesame's [HTTP API][Sesame API].

* <http://github.com/bendiken/rdf-sesame>

Documentation
-------------

* {RDF::Sesame}
  * {RDF::Sesame::Connection}
  * {RDF::Sesame::Server}
  * {RDF::Sesame::Repository}

This adapter implements the [`RDF::Repository`][RDF::Repository] interface;
refer to the relevant RDF.rb API documentation for further usage instructions.

Limitations
-----------

* This adapter does not contain any SPARQL support. To use a Sesame endpoint
  with SPARQL, see the [`SPARQL::Client`](http://sparql.rubyforge.org/client/)
  gem.
* This adapter is not yet optimized for RDF.rb 0.2.x's bulk-operation APIs,
  meaning that statement insertions and deletions are currently performed
  one by one; this may affect the performance of loading large datasets into
  Sesame. This will be addressed in an upcoming version.
* This adapter is not yet optimized for RDF.rb 0.2.x's enhanced query APIs;
  this may adversely affect triple pattern query performance. This
  will be addressed in an upcoming version.

Caveats
-------

* Sesame rewrites blank node identifiers on inserted statements. For
  example, if you supply a `_:foobar` identifier, it becomes something like
  `_:node156oo6equx12769` as soon as you insert it into a Sesame repository. 
  This means that you can't construct and insert a statement containing a
  blank node term and then expect to successfully be able check for its
  existence using the `Repository#has_statement?` method. This is also the
  reason that 7 specs for `RDF::Repository` currently fail with this
  adapter.

Dependencies
------------

* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.0)
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
