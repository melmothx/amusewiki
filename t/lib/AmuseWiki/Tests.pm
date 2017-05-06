package AmuseWiki::Tests;

use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path remove_tree/;
use Text::Amuse::Compile::Utils qw/write_file/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use Git::Wrapper;
use Search::Xapian;
use DateTime;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/create_site check_jobber_result fill_site/;

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
        my $ajax = from_json($mech->response->content);
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

sub fill_site {
    my $site = shift;
    my $topic = $site->categories->topics_only->create({
                                                        name => 'Topic',
                                                        uri => 'topic',
                                                       });
    my $author = $site->categories->authors_only->create({
                                                          name => 'Author',
                                                          uri => 'author',
                                                         });
    foreach my $id (1..20) {
        my $uri = "a-title-$id-test";
        my $title = $site->titles->create({
                                           title => "A test $uri",
                                           uri => $uri,
                                           pubdate => DateTime->now,
                                           f_path => $uri,
                                           f_name => $uri,
                                           f_archive_rel_path => "a/t",
                                           f_timestamp => 0,
                                           f_full_path_name => $uri,
                                           f_suffix => "muse",
                                           f_class => 'text',
                                           status => 'published',
                                          });
        $title->set_categories([ $topic, $author ]);
        $title->set_monthly_archives([{ site_id => $site->id,
                                        month => $title->pubdate->month,
                                        year => $title->pubdate->year,
                                      }]);
        $title->add_to_title_stats({
                                    site_id => $site->id,
                                    accessed => DateTime->now,
                                   });
        my $xapian = $site->xapian;
        my $db = $xapian->xapian_db;
        my $indexer = Search::Xapian::TermGenerator->new();
        my $doc = Search::Xapian::Document->new();
        $indexer->set_stemmer($xapian->xapian_stemmer);
        $indexer->set_document($doc);
        $doc->set_data($uri);
        $doc->add_term('Q' . $uri);
        $indexer->index_text($uri, 1, 'S');
        $indexer->increase_termpos();
        $indexer->index_text("this uri doesn't exist a abc cdf");
        $db->replace_document_by_term('Q' . $uri, $doc);
    }
}

1;
