package AmuseWiki::Tests;

use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path remove_tree/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Git::Wrapper;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/create_site/;

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
                                                   canonical => $canonical,
                                                  })->discard_changes;

    remove_tree($site->repo_root) if -d $site->repo_root;
    $site->initialize_git;
    return $site;
}

1;
