use utf8;
package AmuseWikiFarm::Schema::Result::Aggregation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Aggregation - Aggregations

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

=head1 TABLE: C<aggregation>

=cut

__PACKAGE__->table("aggregation");

=head1 ACCESSORS

=head2 aggregation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregation_series_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 aggregation_uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 aggregation_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 publication_date

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 publication_data_year

  data_type: 'integer'
  is_nullable: 1

=head2 publication_data_month

  data_type: 'integer'
  is_nullable: 1

=head2 publication_data_day

  data_type: 'integer'
  is_nullable: 1

=head2 issue

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 publication_place

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 publisher

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 isbn

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "aggregation_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "aggregation_series_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "aggregation_uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "aggregation_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "publication_date",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "publication_data_year",
  { data_type => "integer", is_nullable => 1 },
  "publication_data_month",
  { data_type => "integer", is_nullable => 1 },
  "publication_data_day",
  { data_type => "integer", is_nullable => 1 },
  "issue",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "publication_place",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "publisher",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "isbn",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregation_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregation_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<aggregation_uri_site_id_unique>

=over 4

=item * L</aggregation_uri>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "aggregation_uri_site_id_unique",
  ["aggregation_uri", "site_id"],
);

=head1 RELATIONS

=head2 aggregation_series

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::AggregationSeries>

=cut

__PACKAGE__->belongs_to(
  "aggregation_series",
  "AmuseWikiFarm::Schema::Result::AggregationSeries",
  { aggregation_series_id => "aggregation_series_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 aggregation_titles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::AggregationTitle>

=cut

__PACKAGE__->has_many(
  "aggregation_titles",
  "AmuseWikiFarm::Schema::Result::AggregationTitle",
  { "foreign.aggregation_id" => "self.aggregation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-16 13:27:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Khj/5igKi53Uu1SwbQZ7bA

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'aggregation_uri_amw_index', fields => ['aggregation_uri']);
}

sub titles {
    my $self = shift;
    my @uris = map { $_->{title_uri} } $self->aggregation_titles->title_uris->hri->all;
    my %titles = map { $_->uri => $_ }
      $self->site->titles->texts_only->status_is_published->by_uri(\@uris)->all;
    my @out;
    foreach my $uri (@uris) {
        if (my $title = $titles{$uri}) {
            push @out, $title;
        }
    }
    return @out;
}

sub has_details {
    my $self = shift;
    if ($self->publication_place
        or $self->publication_date
        or $self->publisher
        or $self->isbn
        or $self->has_siblings) {
        return 1;
    }
    else {
        return 0;
    }
}

sub has_siblings {
    my $self = shift;
    if ($self->site->aggregations->search({ aggregation_code => $self->aggregation_code })->count > 1) {
        return 1;
    }
    else {
        return 0;
    }
}

sub serialize {
    my $self = shift;
    my %vals = $self->get_columns;
    foreach my $k (qw/aggregation_id site_id/) {
        delete $vals{$k};
    }
    foreach my $k (keys %vals) {
        delete $vals{$k} unless defined $vals{$k};
    }
    $vals{titles} = [ map { $_->{title_uri} } $self->aggregation_titles->title_uris->hri->all ];
    return \%vals;
}

sub bump_oai_pmh_records {
    my $self = shift;
    my @ids = map { $_->id } $self->titles;
    $self->site->oai_pmh_records->by_title_id(\@ids)->bump_datestamp;
}

__PACKAGE__->meta->make_immutable;
1;
