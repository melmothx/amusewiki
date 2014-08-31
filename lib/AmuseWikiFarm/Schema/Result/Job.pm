use utf8;
package AmuseWikiFarm::Schema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Job

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

=head2 completed

  data_type: 'datetime'
  is_nullable: 1

=head2 priority

  data_type: 'integer'
  is_nullable: 1

=head2 produced

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
  "task",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "payload",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "completed",
  { data_type => "datetime", is_nullable => 1 },
  "priority",
  { data_type => "integer", is_nullable => 1 },
  "produced",
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


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-08-11 10:20:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0IlAAomj8TvRa7fy8p3i2w

use Cwd;
use Data::Dumper;


use File::Spec;
use File::Temp;
use File::Copy qw/copy move/;

use Text::Amuse::Compile::Utils qw/read_file append_file/;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use DateTime;
use JSON qw/to_json
            from_json/;

use Text::Amuse::Compile;
use PDF::Imposition;


=head2 as_json

Return the json string for the job, ascii encoded.

=head2 as_hashref

Return the job representation as an hashref

=cut

sub as_hashref {
    my $self = shift;
    my $struct = {
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
                  logs     => $self->logs,
                 };
    return $struct;
}

sub as_json {
    my $self = shift;
    return to_json($self->as_hashref, { ascii => 1, pretty => 1 } );
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
    # guaranteed to exist by log/jobs/README.txt
    die "We're in the wrong directory: " . getcwd()  unless -d $dir;
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
        warn "$logfile exists, renaming to $oldfile\n";
        move($logfile, $oldfile) or warn "WTF?";
    }
}

=head2 logs

Return the content of the log file.

=cut

sub logs {
    my $self = shift;
    my $file = $self->log_file;
    if (-f $file) {
        my $log = read_file($file);
        # obfuscate the current directory
        my $cwd = getcwd();
        $log =~ s/$cwd/./g;
        return $log;
    }
    return '';
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
    my $self = shift;
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
            $output = $self->$method($logger);
        };
        if ($@) {
            $self->status('failed');
            $self->errors($@);
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
        warn "No handler found for $task!\n";
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
    warn "Removing $path\n";
    if (my $git = $site->git) {
        $git->rm($path);
        $git->commit({ message => "$uri deleted by $user" });
    }
    else {
        unlink $path or die "Couldn't delete $path $!\n";
    }
    $text->delete;
    return '/';
}


sub dispatch_job_publish {
    my ($self, $logger) = @_;
    my $id = $self->job_data->{id};
    # will return the $self->title->full_uri
    return $self->site->revisions->find($id)->publish_text($logger);
}

sub dispatch_job_git {
    my ($self, $logger) = @_;
    my $data = $self->job_data;
    my $site = $self->site;
    my $remote = $data->{remote};
    my $action = $data->{action};
    my $validate = $site->remote_gits_hashref;
    die "Couldn't validate" unless $validate->{$remote}->{$action};
    if ($action eq 'fetch') {
        $site->repo_git_pull($remote, $logger);
        $site->update_db_from_tree($logger);
    }
    elsif ($action eq 'push') {
        $site->repo_git_push($remote, $logger);
    }
    else {
        die "Unhandled action $action!";
    }
    return '/';
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

sub customdir {
    return 'custom';
}
sub bb_produced_pdf {
    my $self = shift;
    my $id = $self->id;
    return join('/', '', $self->customdir, $self->bb_pdfname);
}

sub bb_produced_zip {
    my $self = shift;
    return join('/', '', $self->customdir, $self->bb_zipname);
}

sub bb_zipbasename {
    my $self = shift;
    my $id = $self->id;
    return "bookbuilder-$id";
}

sub bb_zipname {
    return shift->bb_zipbasename . '.zip';
}

sub bb_pdfname {
    my $self = shift;
    my $id = $self->id;
    return "$id.pdf";
}

sub produced_files {
    my $self = shift;
    my @out;
    if ($self->task eq 'bookbuilder') {
        foreach my $f ($self->bb_zipname, $self->bb_pdfname) {
            push @out, File::Spec->catfile('root', $self->customdir, $f);
        }
    }
    return @out;
}

sub dispatch_job_bookbuilder {
    my ($self, $logger) = @_;
    my $data = $self->job_data;
    my $jobdir = File::Spec->catdir('root', $self->customdir);
    $jobdir =    File::Spec->rel2abs($jobdir);
    my $homedir = getcwd();
    die "In the wrong dir: $homedir" unless -d $jobdir;

    print Dumper($data);
    # first, get the text list
    my $textlist = $data->{text_list};

    print $self->site->id, "\n";

    my %compile_opts = $self->site->compile_options;
    my $template_opts = $compile_opts{extra};

    # overwrite the site ones with the user-defined (and validated)
    foreach my $k (keys %{ $data->{template_options} }) {
        $template_opts->{$k} = $data->{template_options}->{$k};
    }

    print Dumper($template_opts);

    my $bbdir    = File::Temp->newdir(CLEANUP => 0);
    my $basedir = $bbdir->dirname;

    print "Created $basedir\n";

    my %archives;

    # validate the texts passed looking up the uri in the db
    my @texts;
    foreach my $text (@$textlist) {
        my $title = $self->site->titles->by_uri($text);
        unless ($title) {
            warn "Couldn't find $text\n";
            next;
        }

        push @texts, $text;
        if ($archives{$text}) {
            next;
        }
        else {
            $archives{$text}++;
        }

        # pick and copy the zip in the temporary dir
        my $zip = $title->filepath_for_ext('zip');
        if (-f $zip) {
            copy($zip, $basedir) or die $!;
        }
    }
    die "No text found!" unless @texts;

    chdir $basedir or die $!;
    # extract the archives
    foreach my $i (keys %archives) {
        my $zipfile = $i . '.zip';
        my $zip = Archive::Zip->new;
        unless ($zip->read($zipfile) == AZ_OK) {
            warn "Couldn't read $i.zip";
            next;
        }
        $zip->extractTree($i);
        undef $zip;
        unlink $zipfile or die $!;
    }
    my $compiler = Text::Amuse::Compile->new(
                                             tex => 1,
                                             pdf => 1,
                                             extra => $template_opts,
                                             logger => $logger,
                                            );
    print $compiler->version;

    my $outfile = $self->bb_pdfname;

    if (@texts == 1) {
        my $basename = shift(@texts);
        my $pdfout   = $basename . '.pdf';
        $compiler->compile($basename . '.muse');
        if (-f $pdfout) {
            move($pdfout, $outfile) or die "Couldn't move $pdfout to $outfile";
        }
    }
    else {
        my $target = {
                      path => $basedir,
                      files => \@texts,
                      name => $self->id,
                      title => $data->{title},
                     };
        # compile
        $compiler->compile($target);
    }

    die "$outfile not produced!\n" unless (-f $outfile);

    # imposing needed?
    if ($data->{imposer_options} and %{$data->{imposer_options}}) {

        my %args = %{$data->{imposer_options}};
        $args{file}    =  $outfile;
        $args{outfile} = $self->id. '.imp.pdf';
        $args{suffix}  = 'imp';
        my $imposer = PDF::Imposition->new(%args);
        $imposer->impose;
        # overwrite the original pdf, we can get another one any time
        copy($imposer->outfile, $outfile) or die "Copy to $outfile failed $!";
    }
    copy($outfile, $jobdir) or die "Copy $outfile to $jobdir failed $!";

    # create a zip archive with the temporary directory and serve it.
    my $zipdir = Archive::Zip->new;
    my $zipname = $self->bb_zipbasename;
    $zipdir->addTree($basedir, $zipname) == AZ_OK
      or $logger->("Failed to produce a zip");
    $zipdir->writeToFileNamed(File::Spec->catfile($jobdir,
                                                  $zipname . '.zip')) == AZ_OK
      or $logger->("Failure writing $zipname.zip");

    # chdir back to home
    chdir $homedir or die $!;
    return $self->bb_produced_pdf;
}


__PACKAGE__->meta->make_immutable;
1;
