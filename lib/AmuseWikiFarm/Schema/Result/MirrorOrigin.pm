use utf8;
package AmuseWikiFarm::Schema::Result::MirrorOrigin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::MirrorOrigin - Mirror origin

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

=head1 TABLE: C<mirror_origin>

=cut

__PACKAGE__->table("mirror_origin");

=head1 ACCESSORS

=head2 mirror_origin_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 remote_domain

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 remote_path

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 active

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 status_message

  data_type: 'text'
  is_nullable: 1

=head2 last_downloaded

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mirror_origin_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "remote_domain",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "remote_path",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "active",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "status_message",
  { data_type => "text", is_nullable => 1 },
  "last_downloaded",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mirror_origin_id>

=back

=cut

__PACKAGE__->set_primary_key("mirror_origin_id");

=head1 RELATIONS

=head2 mirror_infos

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::MirrorInfo>

=cut

__PACKAGE__->has_many(
  "mirror_infos",
  "AmuseWikiFarm::Schema::Result::MirrorInfo",
  { "foreign.mirror_origin_id" => "self.mirror_origin_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-12-08 10:10:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oTI0MJmbotyuc+25c1x7rg

use Cwd;
use constant ROOT => getcwd();
use LWP::UserAgent;
use JSON::MaybeXS;
use Try::Tiny;
use AmuseWikiFarm::Log::Contextual;
use DateTime;
use AmuseWikiFarm::Utils::Amuse qw/build_full_uri/;
use Path::Tiny ();
use File::Copy qw/move/;
use Data::Dumper::Concise;

has ua => (is => 'rw',
           isa => 'Object',
           lazy => 1,
           builder => '_build_ua',
          );

sub _build_ua {
    return LWP::UserAgent->new(timeout => 5);
}

sub fetch_remote {
    my ($self) = @_;
    my $url = $self->manifest_url;
    my $res = $self->ua->get($self->manifest_url);
    my %out;
    if ($res->is_success) {
        try {
            $out{data} = decode_json($res->content);
        }
        catch {
            my $err = $_;
            $out{error} = $err;
            log_error { "Failure decoding $url output "};
        };
    }
    else {
        $out{error} = $url . ': ' . $res->status_line;
        log_error { "Failure downloading $url " . $res->status_line };
    }
    return \%out;
}

sub fetch_and_prepare_download {
    my $self = shift;
    my %out;
    if (my $res = $self->fetch_remote) {
        if (my $list = $res->{data}) {
            # unclear if too slow and requiring a job
            $out{job} = $self->prepare_download($list);
        }
        else {
            $out{error} = $res->{error} || "No data";
        }
    }
    else {
        $out{error} = "Could not fetch, should not happen";
    }
    return \%out;
}


sub remote_target_url {
    my $self = shift;
    my $path = $self->remote_path;
    my $base_url = $self->remote_base_url;
    s/\/+\z// for ($path, $base_url);
    return "${base_url}${path}";
}


sub manifest_url {
    shift->remote_target_url . "/manifest.json";
}

sub remote_base_url {
    my $self = shift;
    my $protocol = $ENV{AMW_MIRROR_USE_HTTP} ? 'http' : 'https';
    my $domain = $self->remote_domain;
    return "${protocol}://${domain}"
}

sub prepare_download {
    my ($self, $list) = @_;
    my $site = $self->site;
    my $now = DateTime->now;
    # here we loop over the list of files to mirror, and we create the
    # placeholder records.
    my %seen;
    my @downloads;
    my $base_url = $self->remote_base_url;
  ITEM:
    foreach my $i (@$list) {
        my ($base, $suffix);
        if ($i->{uri} =~ m/\A([a-z0-9-]+)(\.[a-z0-9]{3,})?\z/) {
            ($base, $suffix) = ($1, $2);
        }
        else {
            Dlog_error { "Invalid specification $_" } $i;
            next ITEM;
        }
        my $rs;
        my %search = (
                      uri => $i->{uri},
                      f_class => $i->{f_class},
                     );
        my %bogus = (
                     f_path => '',
                     f_archive_rel_path => '',
                     f_full_path_name => '',
                     f_name => '',
                     f_suffix => '',
                     f_timestamp => DateTime->from_epoch(epoch => 1),
                    );
        if ($i->{class} eq 'Title') {
            $bogus{status} = 'editing';
            $bogus{pubdate} = DateTime->now;
            unless ($i->{f_class} =~ m/\A (?: text | special ) \z/x) {
                Dlog_error { "Invalid f_class for $_" } $i;
                next ITEM;
            }
            unless ($suffix eq '.muse') {
                Dlog_error { "Suffix must be .muse in $_" } $i;
                next ITEM;
            }
            $search{uri} = $base;
            $rs = $site->titles->search(\%search);
        }
        elsif ($i->{class} eq 'Attachment') {
            $rs = $site->attachments->search(\%search);
            unless ($i->{f_class} =~ m/\A (?: special_image | image | upload_binary | upload_pdf ) \z/x) {
                Dlog_error { "Invalid f_class" } $i;
                next ITEM;
            }
        }
        else {
            Dlog_error { "Invalid class $_" } $i;
            next ITEM;
        }
        my $obj;
        if ($rs->count) {
            log_debug { "$i->{f_class} $i->{uri} exists" };
            $obj = $rs->single;
        }
        else {
            log_debug { "$i->{f_class} $i->{uri} missing, creating" };
            $obj = $rs->create({
                                %bogus,
                               });
        }

        my $full_uri = build_full_uri($i);
        unless ($full_uri) {
            Dlog_error { "Cannot build url from $_" } $i;
            next ITEM;
        }
        my $our_origin_id = $self->mirror_origin_id;
        my %spec = (
                    last_updated => $now,
                    mirror_origin_id => $our_origin_id,
                    download_source => join('', $base_url, $full_uri),
                   );
        my $mirror_info = $obj->mirror_info
          || $obj->create_related('mirror_info', { %spec, site_id => $self->site_id })->discard_changes;

        $seen{$mirror_info->mirror_info_id}++;

        # if there's a mirror exception, leave it alone.
        next ITEM if $mirror_info->mirror_exception;

        my $checksum_mismatch = ($mirror_info->checksum // '') ne ($i->{checksum} // '') ? 1 : 0;

        # has an origin?
        if (my $their_origin_id = $mirror_info->mirror_origin_id) {
            # if same origin: download if mismatch, otherwise nothing to do: either
            # they are not ours or don't need download.
            if ($their_origin_id == $our_origin_id and $checksum_mismatch) {
                push @downloads, $mirror_info->mirror_info_id;
                $mirror_info->update(\%spec);
                log_info { "Downloading $spec{download_source} because mismatching/missing checksum" };
            }
        }
        # not taken but matching checksum: take for future updates
        elsif ($i->{checksum} and !$checksum_mismatch)  {
            log_info { "Taking $spec{download_source} for future downloads" };
            $mirror_info->update(\%spec);
        }
        # not taken but with mismatches
        else {
            log_info { "Placing exception for " . $i->{uri} };
            $mirror_info->update({
                                  mirror_exception => 'conflict',
                                  last_updated => $now,
                                 });
        }
    }
    # Now check the vanished files. We place an exception so it will pop up in the console
    $self->mirror_infos->search({ mirror_info_id => { -not_in => [ sort keys %seen ] } })
      ->update({
                mirror_exception => 'removed_upstream',
                last_updated => $now,
               });
    # and create the bulk job
    my $payload = AmuseWikiFarm::Utils::Amuse::to_json({ mirror_origin_id => $self->mirror_origin_id });
    return $site->bulk_jobs->mirrors->create({
                                       created => $now,
                                       status => (scalar(@downloads) ? 'active' : 'completed'),
                                       completed => (scalar(@downloads) ? undef : $now),
                                       username => 'amusewiki',
                                       payload => $payload,
                                       jobs => [
                                                map {
                                                    +{
                                                      site_id => $site->id,
                                                      username => 'amusewiki',
                                                      task => 'download_remote',
                                                      status => 'pending',
                                                      created => $now,
                                                      priority => 26, # before static indexes
                                                      payload => AmuseWikiFarm::Utils::Amuse::to_json({ id => $_ }),
                                                     }
                                                } @downloads ]
                                      });
}

sub total_files {
    shift->mirror_infos->count;
}

sub download_file {
    my ($self, $info, $logger, $opts) = @_;
    $opts ||= {};
    my $ua = $opts->{ua} || $self->ua;
    my $suffix = $info->is_attachment ? '' : '.muse';
    my $src = $info->download_source;
    my $dest = Path::Tiny::path(ROOT, qw/var cache mirroring/, $info->mirror_origin_id, $info->mirror_info_id . $suffix);
    $dest->parent->mkpath;
    log_info { "Retrieving $src and storing in $dest" };
    my $res = $ua->get($src);
    $logger->("Downloading $src: " . $res->status_line . "\n");
    if ($res->is_success) {
        $dest->spew_raw($res->content);
        $info->update({ download_destination => "$dest" });
        return $src;
    }
    else {
        die "Error downloading $src:" . $res->status_line;
    }
}

sub install_downloaded {
    my ($self, $logger, $opts) = @_;
    $logger->("Installing downloaded files\n");
    my @files;
    foreach my $mi ($self->mirror_infos->download_completed->all) {
        if (my $repo_path = $mi->compute_repo_path) {
            $logger->("Installing " . $mi->full_uri . ' into ' . $repo_path . "\n");
            $repo_path->parent->mkpath;
            move($mi->download_destination, "$repo_path");
            $mi->update({ download_destination => '' });
            push @files, "$repo_path";
        }
        else {
            $logger->("Skipping " . Dumper({ $mi->get_columns }));
        }
    }
    Dlog_debug { "Files to add to git are $_" } \@files;
    my $site = $self->site;
    if (@files) {
        if (my $git = $site->git) {
            foreach my $f (@files) {
                $git->add($f);
            }
            if ($git->status->get('indexed')) {
                my $msg = "Remote changes from " . $self->remote_domain . $self->remote_path;
                log_info { "Committing $msg" };
                $git->commit({ message => $msg });
            }
        }
    }
    $site->update_db_from_tree_async;
}

before delete => sub {
    my $self = shift;
    # when deleting an origin, reset the exceptions and the download source
    $self->mirror_infos->update({
                                 download_source => undef,
                                 mirror_exception => '',
                                });
};

__PACKAGE__->meta->make_immutable;
1;
