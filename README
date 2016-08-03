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

* [RDF.rb](http://rubygems.org/gems/rdf) (~> 1.1)
* [JSON](http://rubygems.org/gems/json_pure) (~> 1.8)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `RDF::Sesame` gem, do:

    % [sudo] gem install rdf-sesame

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/rdf-sesame.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget https://github.com/ruby-rdf/rdf-sesame/tarball/master

Tests
-----

In order to run test, you should use dotenv (which is set as a development dependency) and have a .env file with the following environment variables:
```
SESAME_URL=http://localhost:8080/openrdf-sesame # has to be an accessible openrdf-sesame server
SESAME_REPOSITORY=integration_test # has to be the name of an existing repository on which we'll be doing the integration tests.
```

You can then run them with:

    % bundle exec dotenv rake spec

Mailing List
------------

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

Author
------

* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Aymeric Brisse](http://github.com/abrisse)

Contributors
------------

* [Slava Kravchenko](http://github.com/cordawyn)

License
-------

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[RDF.rb]:          http://rdf.rubyforge.org/
[RDF::Repository]: http://rdf.rubyforge.org/RDF/Repository.html
[Sesame 2.0]:      http://www.openrdf.org/
[Sesame API]:      http://www.openrdf.org/doc/sesame2/system/ch08.html
