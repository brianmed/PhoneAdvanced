use utf8;
package ScotchEgg::Schema::Result::OctocallNbr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::OctocallNbr

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<octocall_nbr>

=cut

__PACKAGE__->table("octocall_nbr");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'octocall_nbr_id_seq'

=head2 octocall_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 number

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 num_calls

  data_type: 'integer'
  is_nullable: 0

=head2 last_call

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 call_status

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
    sequence          => "octocall_nbr_id_seq",
  },
  "octocall_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "number",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "num_calls",
  { data_type => "integer", is_nullable => 0 },
  "last_call",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "call_status",
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

=head1 UNIQUE CONSTRAINTS

=head2 C<octocall_nbr_octocall_id_number_key>

=over 4

=item * L</octocall_id>

=item * L</number>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "octocall_nbr_octocall_id_number_key",
  ["octocall_id", "number"],
);

=head1 RELATIONS

=head2 octocall

Type: belongs_to

Related object: L<ScotchEgg::Schema::Result::Octocall>

=cut

__PACKAGE__->belongs_to(
  "octocall",
  "ScotchEgg::Schema::Result::Octocall",
  { id => "octocall_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:48:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0MIyaQRFGdU9BZL7yoMQlg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
