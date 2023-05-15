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

=head2 identifier

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=head2 datestamp

  data_type: 'datetime'
  is_nullable: 1

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

=head2 metadata_identifier

  data_type: 'varchar'
  is_nullable: 1
  size: 512

=head2 metadata_type

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 metadata_format

  data_type: 'varchar'
  is_nullable: 1
  size: 32

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
  "identifier",
  { data_type => "varchar", is_nullable => 0, size => 512 },
  "datestamp",
  { data_type => "datetime", is_nullable => 1 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "custom_formats_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "metadata_identifier",
  { data_type => "varchar", is_nullable => 1, size => 512 },
  "metadata_type",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "metadata_format",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "deleted",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "update_run",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</identifier>

=back

=cut

__PACKAGE__->set_primary_key("identifier");

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
  { "foreign.oai_pmh_record_id" => "self.identifier" },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-05-12 11:29:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m6MSrfj/ePYBslQhU72bpg

__PACKAGE__->add_columns('+datestamp' => { timezone => 'UTC' });

use AmuseWikiFarm::Utils::Amuse;

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

    my @out = ([ header => [ $deleted ? (status => 'deleted') : () ], # header
                 # children
                 [
                  [ identifier => $self->identifier ],
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
                   $self->dublin_core_record,
                 ];
        push @out, [ metadata => [ $dc ] ];
    }
    return \@out;
}

sub dublin_core_record {
    my $self = shift;
    my $obj = $self->title || $self->attachment;
    unless ($obj) {
        return [
                [ 'dc:title' => 'Removed entry' ],
                [ 'dc:description' => 'This entry was deleted' ],
               ];
    }
    die "Nor a title nor an attachment?" unless $obj;
    my $data = $obj->dublin_core_entry;
    $data->{identifier} = $self->metadata_identifier;
    $data->{format} = $self->metadata_format;
    $data->{type} = $self->metadata_type;
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
                if ($cleaned) {
                    push @out, [ 'dc:' . $k => $cleaned ];
                }
            }
            if ($k eq 'description') {
                if (my $cf = $self->custom_format) {
                    if (my $cf_name = $cf->format_name) {
                        push @out, [ 'dc:' . $k, $cf_name ]
                    }
                }
            }
        }
    }
    return \@out;
}


__PACKAGE__->meta->make_immutable;
1;
