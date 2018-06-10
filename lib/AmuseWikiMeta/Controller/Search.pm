package AmuseWikiMeta::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::Xapian;
use AmuseWikiFarm::Utils::Paginator;
use Path::Tiny;

sub search :Chained('/root') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub ajax :Chained('search') :Args(0) {
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

    my @sites = $c->model('DB::Site')->public_only;
    my $res = $xapian->faceted_search(%params,
                                      published_only => 1,
                                      facets => 0,
                                      filters => 1,
                                     );

    my $baseres = $xapian->faceted_search(%params,
                                          published_only => 1,
                                          filters => 0,
                                          facets => 1);
    my $site_map = { map { $_->id => $_->canonical_url } @sites };
    my $hostname_map = { map { $_->canonical => $_->sitename }  @sites };

    $baseres->sites_map($site_map);
    $res->sites_map($site_map);
    $baseres->languages_map($sites[0]->known_langs);
    $baseres->hostname_map($hostname_map);

    my $pager = AmuseWikiFarm::Utils::Paginator::create_pager($res->pager, sub { $_[0] });

    my $facets = $baseres->facet_tokens;
    my $has_facets = 0;
    foreach my $facet (@$facets) {
        if (@{$facet->{facets}}) {
            $has_facets = 1;
            last;
        }
    }
    my @sorter = ({ value => "", label => "By relevance" },
                  { value => "title_asc", label => "By title A-Z" },
                  { value => "title_desc", label => "By title Z-A" },
                  { value => "pubdate_asc", label => "Older first" },
                  { value => "pubdate_desc", label => "Newer first" },
                  { value => "pages_asc", label => "By number of pages, ascending" },
                  { value => "pages_desc", label => "By number of pages, descending" });
    my $selected = $params{sort} || "";
    foreach my $sort (@sorter) {
        if ($selected eq $sort->{value}) {
            $sort->{active} = 1;
        }
    }
    $c->stash(json => {
                       matches => $res->json_output,
                       filters => $facets,
                       filters_needed => $has_facets,
                       pager_needed => $pager->needed,
                       pager => $pager->items,
                       sorter => \@sorter,
                      });
    Dlog_debug { "json is $_" } $c->stash->{json};
}

__PACKAGE__->meta->make_immutable;

1;
