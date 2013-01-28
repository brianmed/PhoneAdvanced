use utf8;
package ScotchEgg::Schema::Result::PhoneLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::PhoneLog

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phone_log>

=cut

__PACKAGE__->table("phone_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phone_log_id_seq'

=head2 sub

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 caller

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 called

  data_type: 'varchar'
  is_nullable: 0
  size: 60

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
    sequence          => "phone_log_id_seq",
  },
  "sub",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "caller",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "called",
  { data_type => "varchar", is_nullable => 0, size => 60 },
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

=head2 phone_keys

Type: has_many

Related object: L<ScotchEgg::Schema::Result::PhoneKey>

=cut

__PACKAGE__->has_many(
  "phone_keys",
  "ScotchEgg::Schema::Result::PhoneKey",
  { "foreign.phone_log_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tebl/9dw/jwMGC5zYV7FAA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
