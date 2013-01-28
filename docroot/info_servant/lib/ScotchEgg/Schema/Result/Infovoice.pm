use utf8;
package ScotchEgg::Schema::Result::Infovoice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::Infovoice

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<infovoice>

=cut

__PACKAGE__->table("infovoice");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'infovoice_id_seq'

=head2 account_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 twiml

  data_type: 'text'
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  is_nullable: 0
  size: 30

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
    sequence          => "infovoice_id_seq",
  },
  "account_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "twiml",
  { data_type => "text", is_nullable => 0 },
  "status",
  { data_type => "varchar", is_nullable => 0, size => 30 },
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

=head2 account

Type: belongs_to

Related object: L<ScotchEgg::Schema::Result::Account>

=cut

__PACKAGE__->belongs_to(
  "account",
  "ScotchEgg::Schema::Result::Account",
  { id => "account_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 infovoice_nbrs

Type: has_many

Related object: L<ScotchEgg::Schema::Result::InfovoiceNbr>

=cut

__PACKAGE__->has_many(
  "infovoice_nbrs",
  "ScotchEgg::Schema::Result::InfovoiceNbr",
  { "foreign.infovoice_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:48:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cfmeDVcstOPVZYVuTsxfpw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
