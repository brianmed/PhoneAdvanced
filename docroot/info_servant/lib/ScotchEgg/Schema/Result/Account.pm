use utf8;
package ScotchEgg::Schema::Result::Account;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ScotchEgg::Schema::Result::Account

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<account>

=cut

__PACKAGE__->table("account");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'account_id_seq'

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 display_name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 verified

  data_type: 'varchar'
  default_value: 'NOTSENT'
  is_nullable: 0
  size: 128

=head2 accountsid

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 stripe_code

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 updated

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 inserted

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "account_id_seq",
  },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "display_name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "verified",
  {
    data_type => "varchar",
    default_value => "NOTSENT",
    is_nullable => 0,
    size => 128,
  },
  "accountsid",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "stripe_code",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "updated",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "inserted",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
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

=head2 C<account_accountsid_key>

=over 4

=item * L</accountsid>

=back

=cut

__PACKAGE__->add_unique_constraint("account_accountsid_key", ["accountsid"]);

=head2 C<account_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("account_email_key", ["email"]);

=head2 C<account_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("account_name_key", ["name"]);

=head2 C<account_stripe_code_key>

=over 4

=item * L</stripe_code>

=back

=cut

__PACKAGE__->add_unique_constraint("account_stripe_code_key", ["stripe_code"]);

=head1 RELATIONS

=head2 ext_nbr

Type: might_have

Related object: L<ScotchEgg::Schema::Result::ExtNbr>

=cut

__PACKAGE__->might_have(
  "ext_nbr",
  "ScotchEgg::Schema::Result::ExtNbr",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 infovoices

Type: has_many

Related object: L<ScotchEgg::Schema::Result::Infovoice>

=cut

__PACKAGE__->has_many(
  "infovoices",
  "ScotchEgg::Schema::Result::Infovoice",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 int_nbr

Type: might_have

Related object: L<ScotchEgg::Schema::Result::IntNbr>

=cut

__PACKAGE__->might_have(
  "int_nbr",
  "ScotchEgg::Schema::Result::IntNbr",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 octocalls

Type: has_many

Related object: L<ScotchEgg::Schema::Result::Octocall>

=cut

__PACKAGE__->has_many(
  "octocalls",
  "ScotchEgg::Schema::Result::Octocall",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 profiles

Type: has_many

Related object: L<ScotchEgg::Schema::Result::Profile>

=cut

__PACKAGE__->has_many(
  "profiles",
  "ScotchEgg::Schema::Result::Profile",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_keys

Type: has_many

Related object: L<ScotchEgg::Schema::Result::UserKey>

=cut

__PACKAGE__->has_many(
  "user_keys",
  "ScotchEgg::Schema::Result::UserKey",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-27 14:48:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:etifXVUH6Is/O+7M2qooDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
