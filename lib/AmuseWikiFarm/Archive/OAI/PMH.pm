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



1;
