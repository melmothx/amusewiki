use utf8;
package AmuseWikiFarm::Schema::Result::TextMonth;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::TextMonth - Linking table between texts and monthly archives

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<text_month>

=cut

__PACKAGE__->table("text_month");

=head1 ACCESSORS

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 monthly_archive_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "monthly_archive_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</title_id>

=item * L</monthly_archive_id>

=back

=cut

__PACKAGE__->set_primary_key("title_id", "monthly_archive_id");

=head1 RELATIONS

=head2 monthly_archive

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::MonthlyArchive>

=cut

__PACKAGE__->belongs_to(
  "monthly_archive",
  "AmuseWikiFarm::Schema::Result::MonthlyArchive",
  { monthly_archive_id => "monthly_archive_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0/Z86bey9tje1GwMZG3B5g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
