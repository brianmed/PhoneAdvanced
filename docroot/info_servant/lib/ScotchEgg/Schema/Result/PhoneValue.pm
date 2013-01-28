use utf8;
package ScotchEgg::Schema::Result::PhoneValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::PhoneValue

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phone_value>

=cut

__PACKAGE__->table("phone_value");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phone_value_id_seq'

=head2 phone_key_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phone_value

  data_type: 'varchar'
  is_nullable: 0
  size: 2048

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
    sequence          => "phone_value_id_seq",
  },
  "phone_key_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phone_value",
  { data_type => "varchar", is_nullable => 0, size => 2048 },
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

=head2 C<phone_value_phone_key_id_key>

=over 4

=item * L</phone_key_id>

=back

=cut

__PACKAGE__->add_unique_constraint("phone_value_phone_key_id_key", ["phone_key_id"]);

=head1 RELATIONS

=head2 phone_key

Type: belongs_to

Related object: L<ScotchEgg::Schema::Result::PhoneKey>

=cut

__PACKAGE__->belongs_to(
  "phone_key",
  "ScotchEgg::Schema::Result::PhoneKey",
  { id => "phone_key_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RTpIo8fyF/9hiROxoTWkIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
