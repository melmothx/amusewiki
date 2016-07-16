package AmuseWiki::Tests;

use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path remove_tree/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Git::Wrapper;
use JSON qw/decode_json/;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/create_site check_jobber_result/;

=head2 create_site($schema, $id)

Create a site with id C<$id> inside the DBIC schema $schema and return
a Git::Wrapper object for the repo.

Existing trees and db objects are removed.

=cut



sub create_site {
    my ($schema, $id) = @_;
    die unless $id;
    if (my $stray = $schema->resultset('Site')->find($id)) {
        if ( -d $stray->repo_root) {
            remove_tree($stray->repo_root);
        }
        $stray->delete;
    }
    my $canonical = $id . '.amusewiki.org';
    my $site = $schema->resultset('Site')->create({
                                                   id => $id,
                                                   locale => 'en',
                                                   a4_pdf => 0,
                                                   pdf => 0,
                                                   epub => 0,
                                                   lt_pdf => 0,
                                                   mode => 'blog',
                                                   secure_site => 1,
                                                   canonical => $canonical,
                                                  })->discard_changes;

    remove_tree($site->repo_root) if -d $site->repo_root;
    $site->initialize_git;
    return $site;
}

sub check_jobber_result {
    my $mech = shift;
    my $task_path = $mech->response->base->path;
    my ($task_id) = $task_path =~ m{^/tasks/status/(.*)};
    die unless $task_id;
    my $success;
    for (1..30) {
        $mech->get("/tasks/status/$task_id/ajax");
        my $ajax = decode_json($mech->response->content);
        if ($ajax->{status} eq 'completed') {
            $success = $ajax;
            last;
        }
        elsif ($ajax->{status} eq 'failed') {
            die $ajax->{errors};
            return;
        }
        sleep 1;
    }
    return $success;
}


1;
