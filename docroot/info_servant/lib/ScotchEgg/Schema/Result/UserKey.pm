use utf8;
package ScotchEgg::Schema::Result::UserKey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::UserKey

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_key>

=cut

__PACKAGE__->table("user_key");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_key_id_seq'

=head2 account_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_key

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
    sequence          => "user_key_id_seq",
  },
  "account_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_key",
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

=head1 UNIQUE CONSTRAINTS

=head2 C<user_key_account_id_user_key_key>

=over 4

=item * L</account_id>

=item * L</user_key>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "user_key_account_id_user_key_key",
  ["account_id", "user_key"],
);

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

=head2 user_value

Type: might_have

Related object: L<ScotchEgg::Schema::Result::UserValue>

=cut

__PACKAGE__->might_have(
  "user_value",
  "ScotchEgg::Schema::Result::UserValue",
  { "foreign.user_key_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:48:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A88O2GBEKhqdC9nzjHdDAA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
