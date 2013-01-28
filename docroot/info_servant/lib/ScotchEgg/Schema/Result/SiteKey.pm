use utf8;
package ScotchEgg::Schema::Result::SiteKey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::SiteKey

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<site_key>

=cut

__PACKAGE__->table("site_key");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'site_key_id_seq'

=head2 site_key

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=head2 updated

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 inserted

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "site_key_id_seq",
  },
  "site_key",
  { data_type => "varchar", is_nullable => 0, size => 512 },
  "updated",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "inserted",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 site_value

Type: might_have

Related object: L<ScotchEgg::Schema::Result::SiteValue>

=cut

__PACKAGE__->might_have(
  "site_value",
  "ScotchEgg::Schema::Result::SiteValue",
  { "foreign.site_key_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-28 05:31:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WO2podiNMkm0l9niqRvGmg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
