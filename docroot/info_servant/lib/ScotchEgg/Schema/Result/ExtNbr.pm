use utf8;
package ScotchEgg::Schema::Result::ExtNbr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::ExtNbr

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ext_nbr>

=cut

__PACKAGE__->table("ext_nbr");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ext_nbr_id_seq'

=head2 account_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 number

  data_type: 'varchar'
  is_nullable: 0
  size: 128

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
    sequence          => "ext_nbr_id_seq",
  },
  "account_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "number",
  { data_type => "varchar", is_nullable => 0, size => 128 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<ext_nbr_account_id_key>

=over 4

=item * L</account_id>

=back

=cut

__PACKAGE__->add_unique_constraint("ext_nbr_account_id_key", ["account_id"]);

=head2 C<ext_nbr_number_key>

=over 4

=item * L</number>

=back

=cut

__PACKAGE__->add_unique_constraint("ext_nbr_number_key", ["number"]);

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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QUcC6PbSC/IaUS14DvsNJw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
