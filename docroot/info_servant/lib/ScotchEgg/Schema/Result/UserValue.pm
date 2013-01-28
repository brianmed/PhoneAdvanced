use utf8;
package ScotchEgg::Schema::Result::UserValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::UserValue

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_value>

=cut

__PACKAGE__->table("user_value");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_value_id_seq'

=head2 user_key_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_value

  data_type: 'varchar'
  is_nullable: 0
  size: 4096

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
    sequence          => "user_value_id_seq",
  },
  "user_key_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_value",
  { data_type => "varchar", is_nullable => 0, size => 4096 },
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

=head2 C<user_value_user_key_id_key>

=over 4

=item * L</user_key_id>

=back

=cut

__PACKAGE__->add_unique_constraint("user_value_user_key_id_key", ["user_key_id"]);

=head1 RELATIONS

=head2 user_key

Type: belongs_to

Related object: L<ScotchEgg::Schema::Result::UserKey>

=cut

__PACKAGE__->belongs_to(
  "user_key",
  "ScotchEgg::Schema::Result::UserKey",
  { id => "user_key_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:48:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+E2YoRkdlDjl7lhs9vzLhw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
