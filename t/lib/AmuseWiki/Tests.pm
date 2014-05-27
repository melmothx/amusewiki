package AmuseWiki::Tests;

use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path remove_tree/;
use File::Slurp qw/write_file/;
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
    my $site = $schema->resultset('Site')->create({
                                                   id => $id,
                                                   locale => 'en',
                                                   a4_pdf => 0,
                                                   pdf => 0,
                                                   epub => 0,
                                                   lt_pdf => 0,
                                                   mode => 'blog',
                                                  })->get_from_storage;

    $site->add_to_vhosts({ name => $id . '.amusewiki.org' });
    remove_tree($site->repo_root) if -d $site->repo_root;
    mkdir $site->repo_root or die $!;

    my $git = Git::Wrapper->new($site->repo_root);

    unless (-d catdir($site->repo_root, '.git')) {
        write_file(catfile($site->repo_root, "README"),
                   { binmode => ':encoding(UTF-8)' },
                   "test repo\n");
        $git->init;
        $git->add('.');
        $git->commit({ message => "Initial import" });
    }
    return $site;
}

1;
