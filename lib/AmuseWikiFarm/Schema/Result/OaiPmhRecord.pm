use utf8;
package AmuseWikiFarm::Schema::Result::OaiPmhRecord;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::OaiPmhRecord - OAI-PMH Records

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

=head1 TABLE: C<oai_pmh_record>

=cut

__PACKAGE__->table("oai_pmh_record");

=head1 ACCESSORS

=head2 oai_pmh_record_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 identifier

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 datestamp

  data_type: 'datetime'
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 attachment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 aggregation_series_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 aggregation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 custom_formats_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 metadata_type

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 metadata_format

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 metadata_format_description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 deleted

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 update_run

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "oai_pmh_record_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "identifier",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "datestamp",
  { data_type => "datetime", is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "aggregation_series_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "aggregation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "custom_formats_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "metadata_type",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "metadata_format",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "metadata_format_description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "deleted",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "update_run",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</oai_pmh_record_id>

=back

=cut

__PACKAGE__->set_primary_key("oai_pmh_record_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<identifier_site_id_unique>

=over 4

=item * L</identifier>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("identifier_site_id_unique", ["identifier", "site_id"]);

=head1 RELATIONS

=head2 aggregation

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Aggregation>

=cut

__PACKAGE__->belongs_to(
  "aggregation",
  "AmuseWikiFarm::Schema::Result::Aggregation",
  { aggregation_id => "aggregation_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

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

=head2 attachment

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Attachment>

=cut

__PACKAGE__->belongs_to(
  "attachment",
  "AmuseWikiFarm::Schema::Result::Attachment",
  { id => "attachment_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 custom_format

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::CustomFormat>

=cut

__PACKAGE__->belongs_to(
  "custom_format",
  "AmuseWikiFarm::Schema::Result::CustomFormat",
  { custom_formats_id => "custom_formats_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 oai_pmh_record_sets

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::OaiPmhRecordSet>

=cut

__PACKAGE__->has_many(
  "oai_pmh_record_sets",
  "AmuseWikiFarm::Schema::Result::OaiPmhRecordSet",
  { "foreign.oai_pmh_record_id" => "self.oai_pmh_record_id" },
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

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 oai_pmh_sets

Type: many_to_many

Composing rels: L</oai_pmh_record_sets> -> oai_pmh_set

=cut

__PACKAGE__->many_to_many("oai_pmh_sets", "oai_pmh_record_sets", "oai_pmh_set");


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-10-14 10:56:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cp9Nn1vN5pIRt/Cw9DyBdw

__PACKAGE__->add_columns('+datestamp' => { timezone => 'UTC' });

use AmuseWikiFarm::Utils::Amuse;
use AmuseWikiFarm::Log::Contextual;

sub zulu_datestamp {
    shift->datestamp->iso8601 . 'Z'
}

sub get_object {
    my $self = shift;
    return $self->title || $self->attachment || $self->aggregation || $self->aggregation_series;
}

sub as_xml_structure {
    my ($self, $prefix, $opts) = @_;
    my @sets;
    foreach my $set ($self->oai_pmh_sets) {
        push @sets, [ setSpec => $set->set_spec ];
    }
    my $deleted = $self->deleted;
    unless ($self->get_object) {
        $deleted = 1;
    }
    # optimization, so we don't need the site object in the loop. Meh for get_record.
    my $site_identifier = $opts->{site_identifier} || $self->site->oai_pmh_base_identifier;

    my @out = ([ header => [ $deleted ? (status => 'deleted') : () ], # header
                 # children
                 [
                  [ identifier => $site_identifier . $self->identifier ],
                  [ datestamp => $self->zulu_datestamp ],
                  @sets
                 ]
               ]);
    return \@out if $opts->{header_only};
    if ($prefix eq 'oai_dc') {
        my $dc = [ 'oai_dc:dc',
                   [
                    'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                    'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                    'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                    'xsi:schemaLocation' => join(' ',
                                                 "http://www.openarchives.org/OAI/2.0/oai_dc/",
                                                 "http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
                                                ),
                   ],
                   $self->dublin_core_record({ prefix => 'dc:' }),
                 ];
        push @out, [ metadata => [ $dc ] ];
    }
    elsif ($prefix eq 'marc21') {
        my $schema_location = join(' ',
                                   "http://www.loc.gov/MARC21/slim",
                                   "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
                                  );
        my $marc21 = [
                      record => [
                                 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                                 'xmlns' => "http://www.loc.gov/MARC21/slim",
                                 'xsi:schemaLocation' => $schema_location,
                                ],
                      $self->marc21_record($opts),
                     ];
        push @out, [ metadata => [ $marc21 ] ];
    }
    return \@out;
}

sub marc21_record {
    my ($self, $opts) = @_;
    my $obj = $self->get_object;
    my $site_identifier = $opts->{site_identifier} || $self->site->oai_pmh_base_identifier;
    unless ($obj) {
        return [
                [
                 datafield => [ tag => '245', ind1 => 0, ind2 => 0 ],
                 [ [ subfield => [ code => 'a'], 'Removed entry' ] ],
                ],
                [
                 datafield => [ tag => '520', ind1 => ' ', ind2 => ' ' ],
                 [ [ subfield => [ code => 'a', ],  'This entry was deleted' ] ],
                ],
               ];
    }
    my $base_url = $self->site->canonical_url;
    my $dc = $obj->dublin_core_entry;
    my %rec = (
               %$dc,
               full_uri => [
                            {
                             u => $base_url . $self->identifier,
                             q => $self->metadata_format || '',
                             y => $self->metadata_format_description || '',
                            }
                           ],
               format => [ $self->metadata_format ],
               type => [ { a => $self->metadata_type, 2 => 'local' } ],
              );
    my %mapping = (
                   contributor => 'collaborator',
                   creator => 'author',
                  );
    foreach my $k (keys %mapping) {
        if ($rec{$k}) {
            $rec{$k} = [ map { +{ a => $_, e => $mapping{$k} } } @{$rec{$k}} ];
        }
    }

    if (my $title = $self->title) {
        $rec{title} = [ $title->title ];
        $rec{subtitle} = [ $title->subtitle ];
        $rec{sku} = [ $title->sku ];
        $rec{isbn} = [ $title->isbn ];
        $rec{sku} = [ $title->sku ];
        # populate the rec here
      ANNOTATION:
        foreach my $ann ($title->title_annotations->public->by_type([qw/text identifier/])) {
            my $annotation = $ann->annotation;
            my $annotation_name = $annotation->annotation_name;
            my $annotation_value = $ann->annotation_value;
            next ANNOTATION unless length($annotation_value);
            if ($annotation_name eq 'slc') {
                $rec{slc} = [ $annotation_value ];
            }
            elsif ($annotation_name eq 'price') {
                if (my $full_price = $annotation_value) {
                    $full_price =~ s/\s//g;
                    if ($full_price =~ m/([^0-9\.\,]+)/) {
                        $rec{trade_price_currency} = [ $1 ];
                        # remove non-numeric
                        $full_price =~ s/[^0-9\.\,]//g;
                        $rec{trade_price_value} = [ $full_price ];
                    }
                    else {
                        $rec{trade_price_value} = [ $full_price ];
                    }
                }
            }
            else {
                push @{$rec{description}}, $annotation->label . ": " . $annotation_value;
            }
        }
        my @aggregations;
        foreach my $agg (map { $_->final_data } $title->aggregations->sorted->all) {
            Dlog_debug { "Aggregation is $_" } $agg;
            my $name = $agg->{aggregation_name};
            if ($agg->{series_data} and $agg->{series_data}->{aggregation_series_name}) {
                $name = $agg->{series_data}->{aggregation_series_name};
            }
            push @aggregations, {
                                 't' => $name,
                                 'g' => $agg->{issue},
                                 'o' => $site_identifier . $agg->{full_uri},
                                 '6' => $base_url . $agg->{full_uri},
                                 'z' => $agg->{isbn},
                                 'd' => $agg->{aggregation_place_publisher_date},
                                 'q' => $agg->{title_sorting_pos},
                                };
        }
        if (@aggregations) {
            $rec{aggregation} = \@aggregations;
        }
    }
    elsif (my $series = $self->aggregation_series) {
        $rec{pub_place} = [ $series->publication_place ];
        my @aggregated;
        foreach my $agg (map { $_->final_data } $series->aggregations->sorted->all) {
            push @aggregated, {
                               't' => $agg->{aggregation_name},
                               'o' => $site_identifier . $agg->{full_uri},
                               '6' => $base_url . $agg->{full_uri},
                               'z' => $agg->{isbn},
                               '8' => $agg->{sorting_pos},
                               'd' => $agg->{aggregation_place_publisher_date},
                              };
        }
        $rec{aggregated} = \@aggregated;
    }
    elsif (my $agg = $self->aggregation) {
        my $data = $agg->final_data;
        $rec{pub_place} = [ $data->{publication_place} ];
        $rec{isbn} = [ $agg->isbn ];
        # here we have both aggregated (titles) and aggregations (series)
        my (@aggregated, @aggregations);
        if (my $serie = $agg->aggregation_series) {
            my $full_uri = $serie->full_uri;
            # serie
            push @aggregations, {
                                 't' => $serie->final_name,
                                 'o' => $site_identifier . $full_uri,
                                 '6' => $base_url . $full_uri,
                                 'd' => $serie->place_publisher_date,
                                 'q' => $agg->sorting_pos,
                                };
        }
        my $title_pos = 0;
        foreach my $title ($agg->published_titles) {
            my $full_uri = $title->full_uri;
            push @aggregated, {
                               't' => $title->author_title,
                               'o' => $site_identifier . $full_uri,
                               '6' => $base_url . $full_uri,
                               'z' => $title->isbn,
                               '8' => ++$title_pos,
                               'd' => join(' ', grep { $_ } $title->publisher, $title->date_year),
                              };
        }
        $rec{aggregated} = \@aggregated;
        $rec{aggregation} = \@aggregations;
    }

    my $type = $rec{type}[0] || '';
    my @out;
    my %leaders = (
                   collection =>  'p',
                   dataset => 'm',
                   event  => 'r',
                   image  => 'k',
                   'interactive resource' =>  'm',
                   service  => 'm',
                   software  => 'm',
                   sound  => 'i',
                   text  => 'a',
                  );
    my $leader06 = $leaders{$type} || 'a';
    my $leader07 = $type eq 'collection' ? 'c' : 'm';
    push @out,
      # taken from https://www.loc.gov/standards/marcxml/xslt/DC2MARC21slim.xsl
      [ leader => '      ' . $leader06 . $leader07 . '         3u     '],
      [ datafield => [ tag => '042', ind1 => ' ', ind2 => ' ' ],
        [
         [ subfield => [ code => 'a' ], 'dc' ]
        ]
      ];

    my @datafields = (
                      [ contributor => '720', '0', '0', qw/a e/],
                      [ coverage    => '500', ' ', ' ', 'a' ],
                      # [ creator     => '720', ' ', ' ', qw/a e/],
                      [ creator     => '100', ' ', ' ', qw/a e/],
                      # date needs refinements
                      [ pub_place   => '260', ' ', ' ', 'a' ],
                      [ publisher   => '260', ' ', ' ', 'b' ],
                      [ date        => '260', ' ', ' ', 'c' ],
                      [ date        => '363', ' ', ' ', 'i' ],
                      [ description => '520', ' ', ' ', 'a' ],
                      [ sku         => '024', '8', ' ', 'a' ],
                      [ language    => '546', ' ', ' ', 'a' ],
                      [ relation    => '787', '0', ' ', 'n' ],
                      [ rights      => '540', ' ', ' ', 'a' ],
                      [ source      => '786', '0', ' ', 'n' ],
                      [ subject     => '653', ' ', ' ', 'a' ],
                      [ title       => '245', '0', '0', 'a' ],
                      [ subtitle    => '246', '3', '3', 'a' ],
                      [ type        => '655', '7', ' ', 'a', '2' ],
                      [ type        => '336', ' ', ' ', 'a' ],
                      [ trade_price_value => '365', ' ', ' ', 'b' ],
                      [ trade_price_currency => '365', ' ', ' ', 'c' ],
                      # koha full call number is 952 o
                      [ slc         => '852', ' ', ' ', 'c' ],
                      [ isbn        => '020', ' ', ' ', 'a' ],
                      [ full_uri    => '856', ' ', ' ', qw/u q y/],
                      [ aggregation => '773', ' ', ' ', qw/t g o 6 z d q  /],
                      [ aggregated =>  '774', ' ', ' ', qw/t   o 6 z d   8/],
                      );
    Dlog_debug { "MARC21: $_" } \%rec;

    foreach my $df (sort { $a->[1] cmp $b->[1] } @datafields) {
        my ($name, $tag, $ind1, $ind2, $code, @rest) = @$df;
        if (my $all = $rec{$name}) {
            foreach my $r (grep { length $_ } @$all) {
                my $item = ref($r) ? $r->{$code} : $r;
                my $cleaned = AmuseWikiFarm::Utils::Amuse::clean_html($item);
                $cleaned =~ s/\A\s+//;
                $cleaned =~ s/\s+\z//;
                if (length($cleaned)) {
                    # special case for author, of course
                    if ($name eq 'creator') {
                        if ($item =~ m/,/) {
                            # by surname
                            $ind1 = '1';
                        }
                        else {
                            # by forename
                            $ind1 = '0';
                        }
                    }
                    my @subfields = ([ subfield => [ code => $code ], $cleaned ]);
                    foreach my $add (@rest) {
                        if (defined $r->{$add} and length($r->{$add})) {
                            push @subfields, [ subfield => [ code => $add ], $r->{$add} ];
                        }
                    }
                    push @out, [ datafield => [ tag => $tag, ind1 => $ind1, ind2 => $ind2 ],
                                 \@subfields ];
                }
            }
        }
    }
    return \@out;
}

sub dublin_core_record {
    my ($self, $opts) = @_;
    my $prefix = "dc:";
    if ($opts and exists $opts->{prefix}) {
        $prefix = $opts->{prefix};
    }
    my $obj = $self->get_object;
    unless ($obj) {
        return [
                [ $prefix . 'title' => 'Removed entry' ],
                [ $prefix . 'description' => 'This entry was deleted' ],
               ];
    }
    my $data = $obj->dublin_core_entry;
    my $base_url = $self->site->canonical_url;
    $data->{identifier} = [ $base_url . $self->identifier ];
    if ($obj->can('isbn')) {
        push @{ $data->{identifier} }, $obj->isbn;
    }
    $data->{format} = $self->metadata_format;
    $data->{type} = $self->metadata_type;
    # It should be always there at this point.
    if (my $fdesc = $self->metadata_format_description) {
        push @{$data->{description}}, $fdesc;
    }
    if ($obj->can('title_annotations')) {
        foreach my $ann ($obj->title_annotations->public) {
            my $annotation_type = $ann->annotation->annotation_type;
            if ($annotation_type eq 'identifier') {
                push @{$data->{identifier}}, $ann->annotation_value;
            }
            if ($annotation_type eq 'text') {
                push @{$data->{description}}, $ann->annotation->label . ": " . $ann->annotation_value;
            }
        }
    }
    # this is the parent.
    $data->{relation} = [ map { $base_url . $_ } @{$data->{relation}} ];

    my @out;
    foreach my $k (qw/title
                      creator
                      subject
                      description
                      publisher
                      contributor
                      date
                      type
                      format
                      identifier
                      source
                      language
                      relation
                      coverage
                      rights/) {
        if (my $v = $data->{$k}) {
            my @list = ref($v) ? (@$v) : ($v);
            foreach my $value (@list) {
                my $cleaned = AmuseWikiFarm::Utils::Amuse::clean_html($value);
                $cleaned =~ s/\A\s+//;
                $cleaned =~ s/\s+\z//;
                if (length($cleaned)) {
                    push @out, [ $prefix . $k => $cleaned ];
                }
            }
        }
    }
    return \@out;
}


__PACKAGE__->meta->make_immutable;
1;
