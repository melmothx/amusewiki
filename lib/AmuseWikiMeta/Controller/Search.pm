package AmuseWikiMeta::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::Xapian;
use Path::Tiny;

sub search :Chained('/root') :PathPart('search') :Args(0) {
    my ($self, $c) = @_;
    # here instead of a directory, we pass a stub database, named xapian.stub
    my $stub = $ENV{AMW_META_XAPIAN_DB} ?
      path($ENV{AMW_META_XAPIAN_DB}) :
      path($c->stash->{amw_meta_root}, 'xapian.stub');
    die "Cannot proceed without $stub stub database" unless -f $stub;
    my $xapian = AmuseWikiFarm::Archive::Xapian->new(multisite => 1,
                                                     stub_database => "$stub",
                                                    );
    my %params = %{$c->req->params};
    my $res = $xapian->faceted_search(%params);
    $c->stash(json => {
                       matches => $res->matches,
                       facets => $res->facet_tokens,
                      });
}

__PACKAGE__->meta->make_immutable;

1;
