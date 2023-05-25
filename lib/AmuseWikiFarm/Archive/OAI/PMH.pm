package AmuseWikiFarm::Archive::OAI::PMH;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Object Str CodeRef HashRef ArrayRef InstanceOf/;
use AmuseWikiFarm::Log::Contextual;
use DateTime;
use AmuseWikiFarm::Utils::Paths;
use Path::Tiny;
use XML::Writer;
use Data::Dumper::Concise;
use Date::Parse;
use JSON::MaybeXS;
use MIME::Base64;

use constant AMW_OAI_PMH_PAGE_SIZE => $ENV{AMW_OAI_PMH_PAGE_SIZE} || 40;

has site => (
             is => 'ro',
             required => 1,
             isa => Object,
            );

has logger => (
               is => 'ro',
               isa => CodeRef,
               default => sub { sub {} },
              );

has oai_pmh_url => (is => 'ro', isa => InstanceOf['URI']);

sub update_site_records {
    my ($self) = @_;
    my $site = $self->site;
    my $schema = $site->result_source->schema;
    # we need to generate an id: oai:
    my $canonical_url = $site->canonical_url;
    my $site_id = $site->id;
    my $formats = $site->formats_definitions;
    my $mime_types = AmuseWikiFarm::Utils::Paths::served_mime_types();
    my $amwset = $site->oai_pmh_sets->update_or_create({
                                                        set_spec => 'amusewiki',
                                                        set_name => 'Files needed to regenerate the archive',
                                                       },
                                                       { key => 'set_spec_site_id_unique' });
    my @files;
    my $rs = $site->titles->published_texts->search(undef,
                                                    {
                                                     prefetch => { title_attachments => 'attachment' }
                                                    });
    my %done;
    while (my $title = $rs->next) {
        # loop over the formats and check the date
        my $identifier = $title->full_uri;
        my $title_id = $title->id;
        # loop over the formats, same as the preamble
        foreach my $f (@$formats) {
            my $file = $title->filepath_for_ext($f->{code});
            my $ext = $f->{ext};
            $ext =~ s/.*\.//;
            push @files, {
                          file => $file,
                          identifier => $identifier . $f->{ext},
                          title_id => $title_id,
                          custom_formats_id => $f->{custom_formats_id},
                          metadata_format => $mime_types->{$ext},
                          sets => $ext eq 'muse' ? [ $amwset ] : [],
                         };
        }
        foreach my $attachment ($title->attachments->public_only->all) {
            push @files, {
                          file => path($attachment->f_full_path_name),
                          identifier => $attachment->full_uri,
                          attachment_id => $attachment->id,
                          metadata_format => $attachment->mime_type,
                          sets => [ $amwset ],
                         };
            $done{$attachment->id}++;
        }
    }
    $self->logger->("Processing " . scalar(@files) . " files for texts\n");
    $rs = $site->attachments->public_only->with_descriptions;
  ATTACHMENT:
    while (my $attachment = $rs->next) {
        unless ($done{$attachment->id}) {
            # these don't belong to a text, but they could belong to a special. No set
            push @files, {
                          file => path($attachment->f_full_path_name),
                          identifier => $attachment->full_uri,
                          attachment_id => $attachment->id,
                          metadata_format => $attachment->mime_type,
                         };
        }
    }
    $self->logger->("Processing " . scalar(@files) . " (including attachments)\n");
    my %all = map { $_->{identifier} => $_ }
      $site->oai_pmh_records->search({ deleted => 0 },
                                     {
                                      result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                                      columns => [qw/oai_pmh_record_id identifier update_run/],
                                     })->all;
    # Dlog_debug { "All: $_ " } \%all;
    # Dlog_debug { "Files: $_ " } [ map { "$_->{file}" } @files ];
    $self->logger->("Collected existing records\n");

    my $now = time();
  FILE:
    foreach my $f (@files) {
        if (my $file = delete $f->{file}) {
            if (-f $file) {
                # $self->logger->("Updating/Creating " . $f->{identifier} . "\n");
                my $epoch_timestamp = (stat($file))[9];
                if (my $existing_rec = delete $all{$f->{identifier}}) {
                    # not modified since last check, skip
                    next FILE if $existing_rec->{update_run} >= $epoch_timestamp;
                }
                $f->{site_id} = $site_id;

                # as datestamp, use the current run
                $f->{update_run} = $now;
                $f->{datestamp} = DateTime->from_epoch(epoch => $now,
                                                       time_zone => 'UTC');
                $f->{deleted} = 0;

                # https://www.dublincore.org/specifications/dublin-core/type-element/
                my $dc_type = 'text';
                my $mime = $f->{metadata_format};
                if ($mime =~ m{^audio\/}) {
                    $dc_type = 'audio';
                }
                elsif ($mime =~ m{^(image|video)/}) {
                    $dc_type = 'image';
                }
                $f->{metadata_type} = $dc_type;
                my $sets = delete $f->{sets} || [];
                my $rec = $site->oai_pmh_records->update_or_create($f, { key => 'identifier_site_id_unique' });
                $rec->set_oai_pmh_sets($sets);
            }
        }
    }
    $self->logger->("Updated existing records\n");
    if (my @removals = map { $_->{oai_pmh_record_id} } values %all) {
        Dlog_info { "Marking those records as removed: $_" } \@removals;
        $site->oai_pmh_records->set_deleted_flag_on_obsolete_records(\@removals, $now);
    }
    $self->logger->("Handled removals\n");
    $self->logger->("Finished\n");
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
        # pass a copy
        $res = $self->$method({ %$params });
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
        die "Bad usage" . Dumper(\@_);
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

sub list_records {
    my ($self, $params) = @_;
    $self->_list_records(ListRecords => $params);
}

sub list_identifiers {
    my ($self, $params) = @_;
    $self->_list_records(ListIdentifiers => $params);
}

sub _list_records {
    my ($self, $action, $params) = @_;
    die "Bad usage" unless $action;
    my $done_so_far = 0;
    if (my $token = $params->{resumptionToken}) {
        # overwrite the parameters
        $params = $self->decode_resumption_token($token);
        unless ($params) {
            return {
                    error_code => 'badResumptionToken',
                    error_message => 'Invalid resumption token',
                   };
        }
        $done_so_far = delete $params->{done_so_far};
    }
    my $prefix = $params->{metadataPrefix};
    unless ($prefix) {
        return {
                error_code => 'badArgument',
                error_message => "Required argument: metadataPrefix",
               };
    }
    if ($prefix ne 'oai_dc') {
        return {
                error_code => 'cannotDisseminateFormat',
                error_message => "Only oai_dc is supported at the moment",
               };
    }
    my %search = (set => '');
    foreach my $date (qw/from until/) {
        if (my $string = $params->{$date}) {
            # 3.3.1
            # The legitimate formats are YYYY-MM-DD and YYYY-MM-DDThh:mm:ssZ
            my $second_granularity;
            if ($string =~ m/\A\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}Z)?\z/) {
                $second_granularity = $1;
            }
            else {
                return {
                        error_code => 'badArgument',
                        error_message => "Invalid $date format",
                       };
            }
            my $epoch;
            eval {
                $epoch = str2time($string, 'UTC');
            };
            if (my $err = $@) {
                log_error { "Bad date $string $err" };
            }
            if ($epoch) {
                if ($epoch > time()) {
                    return {
                            error_code => 'badArgument',
                            error_message => "The date for $date is in the future!",
                           };
                }
                $search{$date} = DateTime->from_epoch(epoch => $epoch,
                                                      time_zone => 'UTC');
                # if it has day granularity, the until should cover the whole day up to now.
                log_debug { "Second granularity for $date is " . ($second_granularity || "day") };
                if ($date eq 'until' and !$second_granularity) {
                    $search{until}->add(days => 1);
                }
            }
            else {
                return {
                        error_code => 'badArgument',
                        error_message => "Invalid date format for $date argument",
                       };
            }
        }
    }
    my $site = $self->site;
    my $site_identifier = $site->oai_pmh_base_identifier;
    if (my $set = $params->{set}) {
        if (my $dbset = $site->oai_pmh_sets->find({ set_spec => $set })) {
            $search{set} = $dbset;
        }
        else {
            return {
                    error_code => 'badArgument',
                    error_message => "Invalid set required",
                   };
        }
    }

    $search{until} ||= DateTime->now(time_zone => 'UTC');
    $search{from}  ||= $site->oai_pmh_records->oldest_record->datestamp;

    log_debug { "Query is from: $search{from} until: $search{until} set: $search{set}" };

    my $rs = $search{set} ? $search{set}->oai_pmh_records : $site->oai_pmh_records;
    $rs = $rs->in_range($search{from}, $search{until})->sorted_for_oai_list;
    my @records;
    my $ids_only = $action eq 'ListIdentifiers' ? 1 : 0;
    my $total = $done_so_far + $rs->count;
    my @items;
    my %xmlargs = (site_identifier => $site_identifier);
    my $is_incomplete = 0;

  RECORD:
    while (my $rec = $rs->next) {
        my $ts = $rec->datestamp;
        if (@items > AMW_OAI_PMH_PAGE_SIZE) {
            # be sure that the last element timestamp is different from the current.
            if ($ts->epoch > $items[-1]->epoch) {
                log_debug { "Item datestamp is $ts and last is " . $items[-1] };
                # prepare the next query
                push @records, $self->encode_resumption_token({
                                                               metadataPrefix => $prefix,
                                                               from => $ts->iso8601 . 'Z',
                                                               until => $search{until}->iso8601 . 'Z',
                                                               # the original set parameter
                                                               set => $params->{set},
                                                               total => $total,
                                                               cursor => $done_so_far,
                                                               done_so_far => $done_so_far + @items,
                                                              });
                $is_incomplete = 1;
                last RECORD;
            }
        }
        push @items, $ts;
        my $xml = $rec->as_xml_structure($prefix,  $ids_only ? { header_only => 1, %xmlargs } : { %xmlargs });
        if ($ids_only) {
            push @records, @$xml;
        }
        else {
            push @records, [ record => $xml ];
        }
    }

    # final part of an incomplete list
    if (!$is_incomplete and $done_so_far) {
        push @records, $self->encode_resumption_token({
                                                       final => 1,
                                                       total => $total,
                                                       cursor => $done_so_far,
                                                       done_so_far => $done_so_far + @items,
                                                      });

    }
    # Dlog_debug { $_ } \@records;
    if (@records) {
        return {
                xml => [
                        [ $action => \@records ]
                       ],
               };
    }
    else {
        return {
                error_code => 'noRecordsMatch',
                error_message => "No results",
               }
    }
}


sub get_record {
    my ($self, $params) = @_;
    my $id = $params->{identifier};
    my $prefix = $params->{metadataPrefix};
    unless ($id && $prefix) {
        return {
                error_code => 'badArgument',
                error_message => "Required arguments: identifier and metadataPrefix",
               };
    }
    if ($prefix ne 'oai_dc') {
        return {
                error_code => 'cannotDisseminateFormat',
                error_message => "Only oai_dc is supported at the moment",
               };
    }
    my ($proto, $canonical, $identifier) = split(':', $id);
    if ($identifier and my $record = $self->site->oai_pmh_records->find({ identifier => $identifier })) {
        return {
                xml => [
                        [ GetRecord => [
                                        [ record => $record->as_xml_structure($prefix) ]
                                       ]
                        ]
                       ]
               };
    }
    else {
        return {
                error_code => 'idDoesNotExist',
                error_message => "$id not found",
               };
    }
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
               [ description => [
                                 [ 'oai-identifier',
                                   [
                                    xmlns => "http://www.openarchives.org/OAI/2.0/oai-identifier",
                                    "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                                    "xsi:schemaLocation" =>
                                    join(" ",
                                         "http://www.openarchives.org/OAI/2.0/oai-identifier",
                                         "http://www.openarchives.org/OAI/2.0/oai-identifier.xsd")
                                   ],
                                   [
                                    [ scheme => 'oai' ],
                                    [ repositoryIdentifier => $site->canonical ],
                                    [ delimiter => ':' ],
                                    [ sampleIdentifier => $site->oai_pmh_base_identifier . "/library/test" ],
                                   ]
                                 ]
                                ]
               ],
              );
    return {
            xml => [[ Identify => \@res  ]]
           };
}

sub earliest_datestamp {
    my $self = shift;
    if (my $first = $self->site->oai_pmh_records->oldest_record) {
        return $first->datestamp->iso8601 . 'Z';
    }
    else {
        return DateTime->now(time_zone => 'UTC')->iso8601 . 'Z';
    }
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

sub decode_resumption_token {
    my ($self, $token) = @_;
    my $out;
    eval {
        $out = decode_json(decode_base64($token));
        die "Not an hashref" unless ref($out) eq 'HASH';
        foreach my $k (qw/metadataPrefix from until set done_so_far total/) {
            die "Bad token, missing $k" unless exists $out->{$k};
        }
        Dlog_debug { "Token: $_" } $out;
    };
    if (my $err = $@) {
        log_error { "Error decoding resumption token: $token: $err" };
    }
    return $out;
}

sub encode_resumption_token {
    my ($self, $spec) = @_;
    my $token;
    unless ($spec->{final}) {
        Dlog_debug { "Next token is $_" } $spec;
        $token = encode_base64(encode_json($spec));
        $token =~ s/\s+//g;
    }
    return [ resumptionToken => [
                                 completeListSize => $spec->{total},
                                 cursor => $spec->{cursor},
                                ], $token ];
}

1;
