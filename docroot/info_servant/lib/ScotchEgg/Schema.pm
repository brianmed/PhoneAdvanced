use utf8;
package ScotchEgg::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rwXeuLf8IGhme10xuHnlYA

my $database = "scotch_egg";
my $username = "kevin";
my $password = "the_trinity";

__PACKAGE__->connection(
    "dbi:Pg:dbname=$database", $username, $password
);

1;
