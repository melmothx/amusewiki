package AmuseWikiFarm::Archive::OAI::PMH;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Object Str HashRef ArrayRef InstanceOf/;
use AmuseWikiFarm::Log::Contextual;
use DateTime;
use AmuseWikiFarm::Utils::Paths;
use Path::Tiny;
use XML::Writer;
use Data::Dumper::Concise;

has site => (
             is => 'ro',
             required => 1,
             isa => Object,
            );

has oai_pmh_url => (is => 'ro', isa => InstanceOf['URI']);

sub update_site_records {
    my ($self) = @_;
    my $site = $self->site;
    my $schema = $site->result_source->schema;
    # we need to generate an id: oai:
    my $base_identifier = join(':', oai => $site->canonical, '');
    my $canonical_url = $site->canonical_url;
    my $site_id = $site->id;
    my $formats = $site->formats_definitions;
    my $mime_types = AmuseWikiFarm::Utils::Paths::served_mime_types();
    Dlog_debug { "Formats and mime types:" . $_ } [ $formats, $mime_types ];

    my @files;
    foreach my $title ($site->titles->published_texts->all) {
        # loop over the formats and check the date
        my $identifier = $base_identifier . $title->full_uri;
        my $title_id = $title->id;
        # loop over the formats, same as the preamble
        foreach my $f (@$formats) {
            my $file = path($title->filepath_for_ext($f->{code}));
            my $ext = $f->{ext};
            $ext =~ s/.*\.//;
            push @files, {
                          file => $file,
                          identifier => $identifier . $f->{ext},
                          metadata_identifier => $canonical_url . $title->full_uri . $f->{ext},
                          title_id => $title_id,
                          metadata_type => 'text',
                          metadata_format => $mime_types->{$ext},
                         };
        }
    }
    foreach my $attachment ($site->attachments->with_descriptions->all) {
        my $identifier = $base_identifier . $attachment->full_uri;
        my $file = path($attachment->f_full_path_name);
        my $mime = $attachment->mime_type;
        # https://www.dublincore.org/specifications/dublin-core/type-element/
        my $dc_type = 'text';
        if ($mime =~ m{^audio\/}) {
            $dc_type = 'audio';
        }
        elsif ($mime =~ m{^(image|video)/}) {
            $dc_type = 'image';
        }
        push @files, {
                      file => $file,
                      identifier => $identifier,
                      attachment_id => $attachment->id,
                      metadata_identifier => $canonical_url . $attachment->full_uri,
                      metadata_type => $dc_type,
                      metadata_format => $mime,
                     };
    }
    my $guard = $schema->txn_scope_guard;
    my $now = time();
    foreach my $f (@files) {
        if (my $file = delete $f->{file}) {
            if ($file->exists) {
                my $mtime = DateTime->from_epoch(epoch => $file->stat->mtime,
                                                 time_zone => 'UTC');
                $f->{site_id} = $site_id;
                $f->{datestamp} = $mtime;
                $f->{update_run} = $now;
                $site->oai_pmh_records->update_or_create($f);
            }
        }
    }
    my $now_utc = DateTime->now(time_zone => 'UTC');
    $site->oai_pmh_records->search({
                                    deleted => 0,
                                    update_run => { '<>' => $now },
                                   })->update({
                                               deleted => 1,
                                               datestamp => $now_utc,
                                              });
    $guard->commit;
}

sub process_request {
    my ($self, $params) = @_;
    my $w = XML::Writer->new(OUTPUT => "self",
                             DATA_INDENT => 2,
                             ENCODING => "UTF-8",
                             DATA_MODE => 1);
    $w->xmlDecl;
    my %verbs = (
                 GetRecord => 'get_record',
                 Identify => 'identify',
                 ListIdentifiers => 'list_identifiers',
                 ListMetadataFormats => 'list_metadata_formats',
                 ListRecords => 'list_records',
                 ListSets => 'list_sets',
                );
    my $verb = $params->{verb} || 'MISSING';
    my $res;
    if (my $method = $verbs{$verb}) {
        $res = $self->$method($params);
    }
    else {
        $res = {
                error_code => 'badVerb',
                error_message => "Bad verb: $verb",
               };
    }
    my @response;
    my %fatals = (
                  badVerb => 1,
                  badArgument => 1,
                 );
    if (my $errcode = $res->{error_code}) {
        push @response, [
                         error => [ code => $errcode ],
                         $res->{error_message} || $errcode
                        ];
        if ($fatals{$errcode}) {
            # In cases where the request that generated this response
            # resulted in a badVerb or badArgument error condition,
            # the repository must return the base URL of the protocol
            # request only. Attributes must not be provided in these
            # cases.
            $params = {};
        }
    }
    if ($res->{xml}) {
        push @response, @{$res->{xml}};
    }
    my $data = [
                'OAI-PMH' => [
                              xmlns => "http://www.openarchives.org/OAI/2.0/" ,
                              'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                              'xsi:schemaLocation' => join(' ',
                                                           "http://www.openarchives.org/OAI/2.0/",
                                                           "http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"
                                                          ),
                             ],
                [
                 [ responseDate => DateTime->now(time_zone => 'UTC')->iso8601 . 'Z' ],
                 [ request => [ %$params ], $self->oai_pmh_url->as_string ],
                 @response,
                ]
               ];
    _generate_xml($w, @$data);
    $w->end;
    return "$w";
}

sub _generate_xml {
    my ($w, $name, @args) = @_;
    my ($attrs, $value);
    if (@args == 0) {
        # all undef
    }
    elsif (@args == 1) {
        $attrs = [];
        $value = $args[0];
    }
    elsif (@args == 2) {
        ($attrs, $value) = @args;
    }
    else {
        die "Bad usage";
    }
    if (defined $value) {
        $w->startTag($name, @$attrs);
        if (ref($value) eq 'ARRAY') {
            foreach my $v (@$value) {
                # recursive call
                _generate_xml($w, @$v)
            }
        }
        elsif (ref($value)) {
            die "Not an array ref! " . Dumper($value);
        }
        else {
            $w->characters($value);
        }
        $w->endTag;
    }
    else {
        $w->emptyTag($name, @$attrs);
    }
}

sub get_record {
}

sub identify {
    my ($self, $params) = @_;
    my $site = $self->site;
    my @res = (
               [ repositoryName => $site->sitename || $site->canonical ],
               [ baseURL => $self->oai_pmh_url->as_string ],
               [ protocolVersion => '2.0' ],
               # I don't think we want more spam
               [ adminEmail => 'postmaster+do-not-use@' . $site->canonical ],
               [ earliestDatestamp => $self->earliest_datestamp ],

               # we keep track but if the instance migrates it's
               # probably lost, no don't make promises for now.
               [ deletedRecord => 'transient' ],
               [ granularity => 'YYYY-MM-DDThh:mm:ssZ' ],
               # let's keep this for later, as it makes validation harder
               # [ description => [
               #                   [ 'oai-identifier',
               #                     [
               #                      xmlns => "http://www.openarchives.org/OAI/2.0/oai-identifier",
               #                      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
               #                      "xsi:schemaLocation" =>
               #                      join(" ",
               #                           "http://www.openarchives.org/OAI/2.0/oai-identifier",
               #                           "http://www.openarchives.org/OAI/2.0/oai-identifier.xsd")
               #                     ],
               #                     [
               #                      [ scheme => 'oai' ],
               #                      [ repositoryIdentifier => $site->canonical ],
               #                      [ delimiter => ':' ],
               #                      [ sampleIdentifier => join(":",'oai' . $site->canonical . "/library/test") ],
               #                     ]
               #                   ]
               #                  ]
               # ],
              );
    return {
            xml => [[ Identify => \@res  ]]
           };
}

sub earliest_datestamp {
    my $self = shift;
    my $first = $self->site->oai_pmh_records->search(undef,
                                                     {
                                                      order_by => { -asc => 'datestamp' },
                                                      rows => 1,
                                                      columns => [qw/datestamp/]
                                                     })->first;
    if ($first) {
        return $first->datestamp->iso8601 . 'Z';
    }
    else {
        return DateTime->now(time_zone => 'UTC')->iso8601 . 'Z';
    }
}

sub list_identifiers {
}

sub list_metadata_formats {
    return {
            xml => [[ ListMetadataFormats => [
                                              [ metadataFormat => [
                                                                   [ metadataPrefix => 'oai_dc' ],
                                                                   [ schema => 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd' ],
                                                                   [ metadataNamespace => 'http://www.openarchives.org/OAI/2.0/oai_dc/' ],
                                                                  ]
                                              ]
                                             ]
                    ]],
            };
}

sub list_records {
}

sub list_sets {
    my $self = shift;
    my $site = $self->site;
    my @out;
    foreach my $set ($site->oai_pmh_sets->all) {
        push @out, [ set => [
                             [ setSpec => $set->set_spec ],
                             [ setName => $set->set_name ],
                            ]];
    }
    if (@out) {
        return {
                xml => [[ ListSets => \@out ]]
               };
    }
    else {
        return {
                error_code => 'noSetHierarchy',
                error_message => "No sets present",
               }
    }
}
1;
