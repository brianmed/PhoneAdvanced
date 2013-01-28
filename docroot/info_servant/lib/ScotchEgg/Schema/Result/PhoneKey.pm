use utf8;
package ScotchEgg::Schema::Result::PhoneKey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::PhoneKey

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phone_key>

=cut

__PACKAGE__->table("phone_key");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phone_key_id_seq'

=head2 phone_log_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phone_key

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
    sequence          => "phone_key_id_seq",
  },
  "phone_log_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phone_key",
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

=head2 C<phone_key_phone_log_id_phone_key_key>

=over 4

=item * L</phone_log_id>

=item * L</phone_key>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "phone_key_phone_log_id_phone_key_key",
  ["phone_log_id", "phone_key"],
);

=head1 RELATIONS

=head2 phone_log

Type: belongs_to

Related object: L<ScotchEgg::Schema::Result::PhoneLog>

=cut

__PACKAGE__->belongs_to(
  "phone_log",
  "ScotchEgg::Schema::Result::PhoneLog",
  { id => "phone_log_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 phone_value

Type: might_have

Related object: L<ScotchEgg::Schema::Result::PhoneValue>

=cut

__PACKAGE__->might_have(
  "phone_value",
  "ScotchEgg::Schema::Result::PhoneValue",
  { "foreign.phone_key_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mMEvS7o0pzTVk8zYODkC1A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
