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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-09-27 10:47:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Xmhs3aN3f4dXdlIaIovXYA

__PACKAGE__->add_columns('+datestamp' => { timezone => 'UTC' });

use AmuseWikiFarm::Utils::Amuse;
use AmuseWikiFarm::Log::Contextual;

sub zulu_datestamp {
    shift->datestamp->iso8601 . 'Z'
}

sub as_xml_structure {
    my ($self, $prefix, $opts) = @_;
    my @sets;
    foreach my $set ($self->oai_pmh_sets) {
        push @sets, [ setSpec => $set->set_spec ];
    }
    my $deleted = $self->deleted;
    unless ($self->title || $self->attachment) {
        $deleted = 1;
    }
    # optimization, so we don't need the site object in the loop. Meh for get_record.
    my $base_id = $opts->{site_identifier} || $self->site->oai_pmh_base_identifier;

    my @out = ([ header => [ $deleted ? (status => 'deleted') : () ], # header
                 # children
                 [
                  [ identifier => $base_id . $self->identifier ],
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
                      $self->marc21_record,
                     ];
        push @out, [ metadata => [ $marc21 ] ];
    }
    return \@out;
}

sub marc21_record {
    my $self = shift;
    my $title = $self->title;
    my $attachment = $self->attachment;
    my $obj = $title || $attachment;
    my $base_url = $self->site->canonical_url;
    my $dc = $obj->dublin_core_entry;
    my %rec = (
               %$dc,
               full_uri => [ $base_url . $self->identifier ],
               format => [ $self->metadata_format ],
               type => [ $self->metadata_type ],
              );
    if ($title) {
        $rec{title} = [ $title->title ];
        $rec{subtitle} = [ $title->subtitle ];
        $rec{sku} = [ $title->sku ];
        $rec{isbn} = [ $title->isbn ];
        $rec{sku} = [ $title->sku ];
        # populate the rec here
        foreach my $ann ($title->title_annotations->public->by_type([qw/text identifier/])) {
            my $annotation = { $ann->annotation->get_columns };
            if ($annotation->{annotation_name} eq 'slc') {
                $rec{slc} = [ $ann->annotation_value ];
            }
            elsif ($annotation->{annotation_name} eq 'price') {
                if (my $full_price = $ann->annotation_value) {
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
                push @{$rec{description}}, $ann->annotation->label . ": " . $ann->annotation_value;
            }
        }
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
                      [ contributor => '720', '0', '0', 'a', e => 'collaborator' ],
                      [ coverage    => '500', ' ', ' ', 'a' ],
                      # [ creator     => '720', ' ', ' ', 'a', e => 'author' ],
                      [ creator     => '100', ' ', ' ', 'a', e => 'author' ],
                      # date needs refinements
                      [ date        => '260', ' ', ' ', 'c' ],
                      [ date        => '363', ' ', ' ', 'i' ],
                      [ description => '520', ' ', ' ', 'a' ],
                      [ sku         => '024', '8', ' ', 'a' ],
                      [ language    => '546', ' ', ' ', 'a' ],
                      [ publisher   => '260', ' ', ' ', 'b' ],
                      [ relation    => '787', '0', ' ', 'n' ],
                      [ rights      => '540', ' ', ' ', 'a' ],
                      [ source      => '786', '0', ' ', 'n' ],
                      [ subject     => '653', ' ', ' ', 'a' ],
                      [ title       => '245', '0', '0', 'a' ],
                      [ subtitle    => '246', '3', '3', 'a' ],
                      [ type        => '655', '7', ' ', 'a', '2', 'local' ],
                      [ type        => '336', ' ', ' ', 'a' ],
                      [ trade_price_value => '365', ' ', ' ', 'b' ],
                      [ trade_price_currency => '365', ' ', ' ', 'c' ],
                      # koha full call number is 952 o
                      [ slc         => '852', ' ', ' ', 'c' ],
                      [ isbn        => '020', ' ', ' ', 'a' ],
                      [ full_uri    => '856', ' ', ' ', 'u',
                        q => $self->metadata_format || '',
                        y => $self->metadata_format_description || ''
                      ],
                     );
    Dlog_debug { "MARC21: $_" } \%rec;

    foreach my $df (sort { $a->[1] cmp $b->[1] } @datafields) {
        my ($name, $tag, $ind1, $ind2, $code, @rest) = @$df;
        if (my $all = $rec{$name}) {
            foreach my $item (grep { length $_ } @$all) {
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
                    while (my @additional = splice @rest, 0, 2) {
                        push @subfields, [ subfield => [ code => $additional[0] ], $additional[1] ];
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
    my $obj = $self->title || $self->attachment;
    unless ($obj) {
        return [
                [ $prefix . 'title' => 'Removed entry' ],
                [ $prefix . 'description' => 'This entry was deleted' ],
               ];
    }
    my $data = $obj->dublin_core_entry;
    my $base_url = $self->site->canonical_url;
    $data->{identifier} = [ $base_url . $self->identifier ];
    $data->{format} = $self->metadata_format;
    $data->{type} = $self->metadata_type;
    push @{$data->{description}}, $self->metadata_format_description || '-';
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
