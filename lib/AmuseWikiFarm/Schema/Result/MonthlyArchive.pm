use utf8;
package AmuseWikiFarm::Schema::Result::MonthlyArchive;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::MonthlyArchive

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

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 TABLE: C<monthly_archive>

=cut

__PACKAGE__->table("monthly_archive");

=head1 ACCESSORS

=head2 monthly_archive_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 month

  data_type: 'integer'
  is_nullable: 0
  size: 2

=head2 year

  data_type: 'integer'
  is_nullable: 0
  size: 4

=cut

__PACKAGE__->add_columns(
  "monthly_archive_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "month",
  { data_type => "integer", is_nullable => 0, size => 2 },
  "year",
  { data_type => "integer", is_nullable => 0, size => 4 },
);

=head1 PRIMARY KEY

=over 4

=item * L</monthly_archive_id>

=back

=cut

__PACKAGE__->set_primary_key("monthly_archive_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_month_year_unique>

=over 4

=item * L</site_id>

=item * L</month>

=item * L</year>

=back

=cut

__PACKAGE__->add_unique_constraint("site_id_month_year_unique", ["site_id", "month", "year"]);

=head1 RELATIONS

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 text_months

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TextMonth>

=cut

__PACKAGE__->has_many(
  "text_months",
  "AmuseWikiFarm::Schema::Result::TextMonth",
  { "foreign.monthly_archive_id" => "self.monthly_archive_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 titles

Type: many_to_many

Composing rels: L</text_months> -> title

=cut

__PACKAGE__->many_to_many("titles", "text_months", "title");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-06-19 17:46:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bERU8NYi5/7djUm2R9IdHg

sub localized_name {
    my ($self, $locale) = @_;
    $locale ||= 'en';
    my $dt = DateTime->new(year => $self->year,
                           month => $self->month,
                           locale => $locale);
    return $dt->format_cldr($dt->locale->format_for('yMMMM'));
}

__PACKAGE__->meta->make_immutable;
1;
