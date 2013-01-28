#!/opt/perl

use DBIx::Class::Schema::Loader qw(make_schema_at);

make_schema_at(
    "ScotchEgg::Schema",
    {
        use_namespaces => 1,
        dump_directory => "/opt/infoservant.com/docroot/info_servant/lib",
    },
    [ "dbi:Pg:dbname=scotch_egg", "kevin", "the_trinity" ],
);
