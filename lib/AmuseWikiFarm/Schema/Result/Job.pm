use utf8;
package AmuseWikiFarm::Schema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Job - Queue for jobs

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

=head1 TABLE: C<job>

=cut

__PACKAGE__->table("job");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 bulk_job_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 task

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 payload

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 created

  data_type: 'datetime'
  is_nullable: 0

=head2 started

  data_type: 'datetime'
  is_nullable: 1

=head2 completed

  data_type: 'datetime'
  is_nullable: 1

=head2 priority

  data_type: 'integer'
  default_value: 10
  is_nullable: 0

=head2 produced

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 errors

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "bulk_job_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "task",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "payload",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "started",
  { data_type => "datetime", is_nullable => 1 },
  "completed",
  { data_type => "datetime", is_nullable => 1 },
  "priority",
  { data_type => "integer", default_value => 10, is_nullable => 0 },
  "produced",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "errors",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 bulk_job

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::BulkJob>

=cut

__PACKAGE__->belongs_to(
  "bulk_job",
  "AmuseWikiFarm::Schema::Result::BulkJob",
  { bulk_job_id => "bulk_job_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 job_files

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::JobFile>

=cut

__PACKAGE__->has_many(
  "job_files",
  "AmuseWikiFarm::Schema::Result::JobFile",
  { "foreign.job_id" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-10-17 11:14:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PIlQOyZOhi1ow/6AiwhzYA

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'job_status_index', fields => ['status']);
}


use Cwd;
use constant ROOT => getcwd();
use File::Spec;
use File::Copy qw/copy move/;
use Text::Amuse::Compile::Utils qw/read_file append_file/;
use DateTime;
use AmuseWikiFarm::Archive::BookBuilder;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse qw/clean_username to_json
                                   from_json/;
use Text::Amuse::Compile;
use HTML::Entities qw/encode_entities/;

has bookbuilder => (is => 'ro',
                    isa => 'Maybe[Object]',
                    lazy => 1,
                    builder => '_build_bookbuilder');

has non_blocking => (is => 'rw',
                     isa => 'Int',
                     default => sub { 0 });

sub can_be_non_blocking {
    my $self = shift;
    my %non_blocking = (
                        build_custom_format => 1,
                        download_remote => 1,
                       );
    return $non_blocking{$self->task};
}

sub _build_bookbuilder {
    my $self = shift;
    if ($self->task eq 'bookbuilder') {
        my $bb = AmuseWikiFarm::Archive::BookBuilder->new(%{$self->job_data},
                                                          site => $self->site,
                                                          job_id => $self->id,
                                                         );
        return $bb;
    }
    else {
        return undef;
    }
}

=head2 as_json

Return the json string for the job, ascii encoded.

=head2 as_hashref

Return the job representation as an hashref

=cut

sub as_hashref {
    my ($self, %opts) = @_;
    my $data = {
                  id       => $self->id,
                  site_id  => $self->site_id,
                  task     => $self->task,
                  payload  => from_json($self->payload),
                  status   => $self->status,
                  created  => $self->created->iso8601,
                  # completed => $self->completed->iso8601,
                  priority => $self->priority,
                  produced => $self->produced,
                  errors   => $self->errors,
                  position => 0,
                  $self->logs_from_offset($opts{offset}),
                 };
    if ($data->{status} eq 'pending') {
        my $pending = $self->result_source->resultset->pending
          ->search({},
                   { columns => [qw/id/] });
        my $found = 0;
        my $position = 0;
        while (my $pend = $pending->next) {
            if ($pend->id eq $self->id) {
                $found = 1;
                last;
            }
            $position++;
        }
        # update the position only if found, there could be a race
        # condition.
        $data->{position} = $position if $found;
    }
    elsif ($data->{status} eq 'completed') {
        $data->{produced} ||= '/';
        if (my $bb = $self->bookbuilder) {
            $data->{message} = 'Your file is ready';
            $data->{sources} = '/custom/' .$bb->sources_filename;
        }
        elsif ($data->{task} eq 'publish') {
            $data->{message} = 'Changes applied';
        }
        else {
            $data->{message} = 'Done';
        }

    }
    return $data;
}

sub as_json {
    my $self = shift;
    return to_json($self->as_hashref);
}

=head2 log_file

Return the location of the log file. Beware that the location is
computed in the current directory, but returned as absolute.

=head2 log_dir

Return the B<absolute> path to the log directory (./log/jobs).

=head2 old_log_file

=head2 make_room_for_logs

Ensure that the file doesn't exit yet.

=cut

sub log_dir {
    my $dir = File::Spec->catdir(qw/log jobs/);
    unless (-d $dir) {
        unless (-d 'log') {
            mkdir 'log' or die "Cannot create log dir! $!";
        }
        mkdir $dir or die "Cannot create  $dir $!";
    }
    return File::Spec->rel2abs($dir);
}


sub log_file {
    my $self = shift;
    return File::Spec->catfile($self->log_dir, $self->id . '.log');
}

sub old_log_file {
    my $self = shift;
    my $now = DateTime->now->iso8601;
    $now =~ s/[^0-9a-zA-Z]/-/g;
    $now .= '-' . int(rand(10000));
    return File::Spec->catfile($self->log_dir, $self->id . '-' . $now . '.log');
}

sub make_room_for_logs {
    my $self = shift;
    my $logfile = $self->log_file;
    if (-f $logfile) {
        my $oldfile = $self->old_log_file;
        log_debug { "$logfile exists, renaming to $oldfile" };
        move($logfile, $oldfile) or log_error { "cannot move $logfile to $oldfile $!" };
    }
}

=head2 logs

Return the content of the log file.

=cut

sub logs {
    my $self = shift;
    my $file = $self->log_file;
    if (-f $file) {
        return $self->obfuscate_logs(read_file($file));
    }
    return '';
}

sub obfuscate_logs {
    my ($self, $log) = @_;
    return '' unless length($log);
    my $cwd = ROOT;
    $log =~ s/\Q$cwd\E/./g;
    return encode_entities($log);
}

sub logs_from_offset {
    my ($self, $offset) = @_;
    my $file = $self->log_file;
    if (-f $file) {
        open (my $fh, '<:encoding(UTF-8)', $file) or return;
        if ($offset and $offset =~ m/\A[1-9][0-9]*\z/) {
            seek $fh, $offset, 0 or return;
        }
        local $/;
        my $log = <$fh>;
        my $new_offset = tell $fh;
        close $fh;
        my %out = (logs => $self->obfuscate_logs($log),
                   (
                    defined $offset ?
                    (offset => $new_offset) : ()
                   ));
        return %out;
    }
    return;
}


=head2 logger

Return a sub for logging into C<log_file>

=cut

sub logger {
    my $self = shift;
    my $logfile = $self->log_file;
    my $logger = sub {
        append_file($logfile, @_);
    };
    return $logger;
}

=head2 dispatch_job

Inspect the content of the job and do it. This is the main method to
trigger a job.

=cut

sub dispatch_job {
    # options are used for debugging.
    my ($self, $options) = @_;
    $self->update({
                   status => 'taken',
                   started => DateTime->now,
                  });
    my $task = $self->task;
    my $handlers = $self->result_source->resultset->handled_jobs_hashref;
    if ($handlers->{$task}) {
        # catch the warns
        my @warnings;
        local $SIG{__WARN__} = sub {
            push @warnings, @_;
        };
        my $method = "dispatch_job_$task";
        $self->make_room_for_logs;
        my $logger = $self->logger;
        $logger->("Job $task started at " . localtime() . "\n");
        my $output;
        eval {
            $output = $self->$method($logger, $options);
        };
        if (my $err = $@) {
            $self->status('failed');
            $self->errors($err);
            log_error { $err . ' ' . $self->logs };
        }
        else {
            $self->completed(DateTime->now);
            $self->status('completed');
            $self->produced($output);
        }
        if (@warnings) {
            $logger->("WARNINGS intercepted:\n", @warnings);
        }
        $logger->("Job $task finished at " . localtime() . "\n");
    }
    else {
        log_error { "No handler found for $task!" };
        $self->status('failed');
        $self->errors("No handler found for $task!\n");
    }
    $self->update;
}

=head2 job_data

Return the deserialized payload, or an empty hashref.

=cut

sub job_data {
    my $self = shift;
    my $payload = $self->payload;
    return {} unless $payload;
    return from_json($payload);
}

sub payload_pretty {
    my $self = shift;
    to_json(from_json($self->payload), pretty => 1, ascii => 0, canonical => 1);
}


=head2 DISPATCHERS

=head3 dispatch_job_publish

Publish the revision

=head3 dispatch_job_testing

Dummy method

=head3 dispatch_job_git

Git push/pull

=head3 dispatch_job_bookbuilder

Bookbuilder job.

=head3 dispatch_job_purge

Purge an already deleted text.

=cut

sub dispatch_job_purge {
    my ($self, $logger) = @_;
    my $data = $self->job_data;
    my $site = $self->site;
    my $text = $site->titles->find($data->{id});
    die "Couldn't find title $data->{id} in this site!\n" unless $text;
    die $text->title . " is not deleted!\n" unless $text->deleted;
    my $user = $data->{username};
    die "No user!" unless $user;
    my $path = $text->f_full_path_name;
    my $uri = $text->full_uri;
    log_info { "Removing $path, purge job" };
    $logger->("Purging " . $text->full_uri . "\n");
    if (my $git = $site->git) {
        local $ENV{GIT_COMMITTER_NAME}  = $self->committer_name;
        local $ENV{GIT_COMMITTER_EMAIL} = $self->committer_mail;
        local $ENV{GIT_AUTHOR_NAME}  = $self->committer_name;
        local $ENV{GIT_AUTHOR_EMAIL} = $self->committer_mail;
        $git->rm($path);
        $git->commit({ message => "$uri deleted by $user" });
        # tested
        log_info { "Syncing the remote repository" };
        $site->sync_remote_repo;
    }
    else {
        unlink $path or die "Couldn't delete $path $!\n";
    }
    $text->delete;
    return '/console/unpublished';
}


sub dispatch_job_publish {
    my ($self, $logger) = @_;
    my $id = $self->job_data->{id};
    Dlog_debug { "job data is $_" } $self->job_data;
    local $ENV{GIT_COMMITTER_NAME}  = $self->committer_name;
    local $ENV{GIT_COMMITTER_EMAIL} = $self->committer_mail;
    # will return the $self->title->full_uri
    return $self->site->revisions->find($id)->publish_text($logger);
}

sub dispatch_job_rebuild {
    my ($self, $logger) = @_;
    if (my $id = $self->job_data->{id}) {
        my $site = $self->site;
        if (my $text = $site->titles->find($id)) {
            my $muse = $text->filepath_for_ext('muse');
            if (-f $muse) {
                my @cfs = grep { $text->wants_custom_format($_) } @{$site->active_custom_formats};
                my $compiler = $site->get_compiler($logger);
                foreach my $cf (@cfs) {
                    $cf->save_canonical_from_aliased_file($muse);
                }
                $compiler->compile($muse);
                foreach my $cf (@cfs) {
                    if ($cf->is_slides and !$text->slides) {
                        $logger->($cf->format_name . " is not needed\n");
                    }
                    else {
                        my $job = $site->jobs->build_custom_format_add({
                                                                        id => $id,
                                                                        cf => $cf->custom_formats_id,
                                                                        force => 1,
                                                                       });
                        $logger->("Scheduled generation of "
                                  . $text->full_uri . '.' . ($cf->valid_alias || $cf->extension)
                                  . " (" .  $cf->format_name .') as task number #'
                                  . $job->id . "\n");
                    }
                }
                # this is relatively fast as we already have the
                # formats built.
                # But still, instruct it that we already have the custom formats.
                $site->compile_and_index_files([ $text ], $logger, skip_custom_formats => 1);
                return $text->full_uri;
            }
            else {
                die "$muse not found";
            }
        }
        else {
            die "Cannot find title with id $id";
        }
    }
    else {
        die "Missing id in the job data";
    }
}

sub dispatch_job_reindex {
    my ($self, $logger) = @_;
    if (my $path = $self->job_data->{path}) {
        my $site = $self->site;
        $site->compile_and_index_files([$path], $logger);
        my $produced = $site->find_file_by_path($path);
        return $produced->full_uri;
    }
    else {
        die "Missing path in the job data";
    }
}

sub dispatch_job_git {
    my ($self, $logger) = @_;
    my $data = $self->job_data;
    my $site = $self->site;
    my $remote = $data->{remote};
    my $action = $data->{action};
    my $validate = $site->remote_gits_hashref;
    die "Couldn't remote $remote for action $action appears invalid!" unless $validate->{$remote}->{$action};
    if ($action eq 'fetch') {
        my @logs = $site->repo_git_pull($remote, $logger);

        # this will call the sync_remote_repo as well.
        my $bulk = $site->update_db_from_tree_async($logger, $self->username);
        my $url = '/tasks/job/' . $bulk->id . '/show';
        $site->send_mail(git_action => {
                                        # no action if those mails are
                                        # not set, as per convention.
                                        to => $site->mail_notify,
                                        from => $site->mail_from,
                                        logs => join("", @logs),
                                        subject => '[' . $site->canonical . "] git pull $remote",
                                        action_url => $site->canonical_url_secure . $url,
                                        expected_documents => $bulk->expected_documents,
                                       }) if $bulk->jobs->count;
        return $url;
    }
    elsif ($action eq 'push') {
        $site->repo_git_push($remote, $logger);
        return '/console/git';
    }
    else {
        die "Unhandled action $action!";
    }
}

sub dispatch_job_alias_create {
    my ($self, $logger) = @_;
    my $data = $self->job_data;
    my $site = $self->site;
    my $alias = $site->redirections->update_or_create({
                                                       uri => $data->{src},
                                                       type => $data->{type},
                                                       redirect => $data->{dest},
                                                      });
    unless ($alias->is_a_category) {
        $alias->delete;
        die "Direct creation possible only for categories\n";
    }
    $logger->("Created alias " . $alias->full_src_uri .
              " pointing to " . $alias->full_dest_uri . "\n");
    if (my $cat = $alias->aliased_category) {
        my @texts = $cat->titles;
        my $cat_uri = $cat->full_uri;
        $logger->("Deleting $cat_uri\n");
        $cat->delete;
        if (@texts) {
            $site->compile_and_index_files(\@texts, $logger);
        }
        else {
            $logger->("No texts found in $cat_uri\n");
        }
    }
    else {
        $logger->("No texts found for " . $alias->full_dest_uri . "\n");
    }
    return '/console/alias';
}

sub dispatch_job_alias_delete {
    my ($self, $logger) = @_;
    my $data = $self->job_data;
    my $site = $self->site;
    if (my $alias = $site->redirections->find($data->{id})) {
        die $alias->full_src_uri . " can't be deleted by us\n"
          unless $alias->can_safe_delete;
        my @texts = $alias->linked_texts;
        $alias->delete;
        if (@texts) {
            $site->compile_and_index_files(\@texts, $logger);
        }
        else {
            $logger->("No texts found for " . $alias->full_dest_uri . "\n");
        }
    }
    return '/console/alias';
}

sub dispatch_job_testing {
    my ($self, $logger) = @_;
    log_debug { "Dispatching fake testing job" };
    return;
}

sub dispatch_job_testing_high {
    my ($self, $logger) = @_;
    log_debug { "Dispatching fake testing job" };
    return;
}


sub produced_files {
    my $self = shift;
    my @out;
    # log file not guaranteed to be there if the job wasn't started.
    if (-f $self->log_file) {
        push @out,  $self->log_file;
    }
    foreach my $file ($self->job_files) {
        my $path = $file->path;
        if (-f $path) {
            push @out, $path;
        }
        else {
            Dlog_error { "$path (in produced files) couldn't be found in " . $_ } $self->job_data;
        }
    }
    return @out;
}

sub dispatch_job_bookbuilder {
    my ($self, $logger) = @_;
    my $bb = $self->bookbuilder;
    if (my $file = $bb->compile($logger)) {
        my $schema = $self->result_source->schema;
        my $guard = $schema->txn_scope_guard;
        $self->add_to_job_files({
                                 filename => $bb->produced_filename,
                                 slot => 'produced',
                                });
        $self->add_to_job_files({
                                  filename => $bb->sources_filename,
                                  slot => 'sources',
                                });
        if (my $cover = $bb->coverfile) {
            # we register it here because we usually want to delete
            # this on job removal. *But*, this file can be reused by
            # subsequent jobs. So the latest wins and takes it over.
            if (my $exist = $schema->resultset('JobFile')->find($cover)) {
                $exist->delete;
            }
            $self->add_to_job_files({
                                     filename => $cover,
                                     slot => 'cover',
                                    });
        }
        $guard->commit;
        return '/custom/' . $bb->produced_filename;
    }
    return;
}

sub dispatch_job_build_static_indexes {
    my ($self, $logger) = @_;
    my $time = time();
    my $missing = $self->site->titles->status_is_published_or_deferred->with_missing_pages_qualification;
    while (my $text = $missing->next) {
        $logger->("Populating text structure for " . $text->full_uri . "\n");
        $text->text_html_structure(1);
    }
    $self->site->static_indexes_generator->generate;
    $self->site->store_file_list_for_mirroring;
    $self->site->store_rss_feed;
    $self->site->store_crawlable_opds_feed;
    $logger->("Generated static indexes " . (time() - $time) . " seconds\n");
    return;
}

sub dispatch_job_build_custom_format {
    my ($self, $logger) = @_;
    my $time = time();
    my $data = $self->job_data;
    my $cf = $self->site->custom_formats->find($data->{cf});
    my $title = $self->site->titles->find($data->{id});
    if ($cf && $title) {
        if ($data->{force} or $cf->needs_compile($title)) {
            if ($cf->compile($title, $logger)) {
                $logger->("Generated " . $cf->format_name . ' for ' . $title->full_uri
                          . ' in ' . (time() - $time) . " seconds\n");
                return $title->full_uri . '.' . $cf->extension;
            }
            else {
                $logger->("Nothing produced for " . $title->full_uri . ' and ' .$cf->format_name . "\n");
            }
        }
        else {
            $logger->($cf->format_name . ' is not needed for ' . $title->full_uri . "\n");
        }
    }
    else {
        $logger->("Couldn't find CF $data->{cf} or title $data->{id}\n");
    }

}

sub dispatch_job_daily_job {
    my ($self, $logger) = @_;
    my $schema = $self->result_source->schema;
    $schema->resultset('TitleStat')->delete_old;
    $schema->resultset('Job')->purge_old_jobs;
    $schema->resultset('Revision')->purge_old_revisions;
    $schema->resultset('Site')->check_and_update_acme_certificates(1);
    return;
}

sub dispatch_job_hourly_job {
    my ($self, $logger) = @_;
    my $schema = $self->result_source->schema;
    $schema->resultset('Job')->fail_stale_jobs;
    $schema->resultset('AmwSession')->delete_expired_sessions;
    # this is the former publish_deferred, the "async" way
    my $deferred = $schema->resultset('Title')->deferred_to_publish(DateTime->now);
    my $username = $self->username;
    while (my $title = $deferred->next) {
        my $site = $title->site;
        my $file = $title->f_full_path_name;
        $site->jobs->reindex_add({ path => $file }, $username);
        $logger->("Scheduled reindex for " . $site->id . $title->full_uri . "\n");
    }
    return;
}

sub dispatch_job_save_bb_cli {
    my $self = shift;
    local $ENV{GIT_COMMITTER_NAME}  = $self->committer_name;
    local $ENV{GIT_COMMITTER_EMAIL} = $self->committer_mail;
    local $ENV{GIT_AUTHOR_NAME}  = $self->committer_name;
    local $ENV{GIT_AUTHOR_EMAIL} = $self->committer_mail;
    $self->site->save_bb_cli;
}

sub dispatch_job_send_mail {
    my $self = shift;
    my $payload = $self->job_data;
    $self->site->send_mail($payload->{type}, $payload->{tokens});
}

sub dispatch_job_download_remote {
    my ($self, $logger, $opts) = @_;
    my $schema = $self->result_source->schema;
    if (my $info = $schema->resultset('MirrorInfo')->find($self->job_data->{id})) {
        if (my $origin = $info->mirror_origin) {
            # just in case
            if ($origin->site_id eq $self->site_id) {
                $origin->download_file($info, $logger, $opts);
            }
            else {
                die $origin->site_id . ' is not ' . $self->site_id;
            }
        }
    }
    if (my $bulk = $self->bulk_job_id) {
        return "/tasks/job/$bulk/show";
    }
    return;
}

sub dispatch_job_install_downloaded {
    my ($self, $logger, $opts) = @_;
    my $spec = $self->job_data;
    if (my $id = $spec->{mirror_origin_id}) {
        if (my $origin = $self->site->mirror_origins->find($id)) {
            local $ENV{GIT_COMMITTER_NAME}  = $self->committer_name;
            local $ENV{GIT_COMMITTER_EMAIL} = $self->committer_mail;
            local $ENV{GIT_AUTHOR_NAME}  = $self->committer_name;
            local $ENV{GIT_AUTHOR_EMAIL} = $self->committer_mail;
            my $bulk = $origin->install_downloaded($logger, $opts);
            return "/tasks/job/" . $bulk->bulk_job_id . "/show";
        }
    }
    return;
}

before delete => sub {
    my $self = shift;
    my @leftovers = $self->produced_files;
    foreach my $file (@leftovers) {
        log_info { "Unlinking $file after job removal" };
        unlink $file or log_error { "Cannot unlink $file $!" };
    }
};

after update => sub {
    my $self = shift;
    # on dispatching, this is called first to set the taken status,
    # and after the dispatching to set the final status.
    if (my $parent = $self->bulk_job) {
        $parent->check_and_set_complete;
    }
};

# same as Result::Revision
sub committer_username {
    my $self = shift;
    return clean_username($self->username);
}
sub committer_name {
    my $self = shift;
    return ucfirst($self->committer_username);
}
sub committer_mail {
    my $self = shift;
    my $hostname = 'localhost';
    if (my $site = $self->site) {
        $hostname = $site->canonical;
    }
    return $self->committer_username . '@' . $hostname;
}

sub is_failed {
   shift->status eq 'failed';
}

sub reschedule {
    my $self = shift;
    if ($self->is_failed) {
        $self->update({
                       status => 'pending',
                       started => undef,
                       completed => undef,
                       produced => undef,
                       errors => undef,
                      });
        return 1;
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;
