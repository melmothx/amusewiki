package AmuseWikiMeta::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::Xapian;
use AmuseWikiFarm::Utils::Paginator;
use AmuseWikiFarm::Utils::Amuse qw/clean_html/;
use Path::Tiny;
use XML::FeedPP;

sub search :Chained('/root') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub ajax :Chained('search') :Args(0) {
    my ($self, $c) = @_;
    # here instead of a directory, we pass a stub database, named xapian.stub
    my $conf = $c->model('DB');
    my $stub = $conf->stub_database;
    log_debug { "Using $stub db" };
    my $xapian = AmuseWikiFarm::Archive::Xapian->new(multisite => 1,
                                                     stub_database => "$stub",
                                                    );
    my %params = %{$c->req->params};

    my $res = $xapian->faceted_search(%params,
                                      published_only => 1,
                                      facets => 0,
                                      filters => 1,
                                     );

    my $baseres = $xapian->faceted_search(%params,
                                          published_only => 1,
                                          filters => 0,
                                          facets => 1);
    $baseres->sites_map($conf->site_map);
    $res->sites_map($conf->site_map);
    $baseres->languages_map($conf->languages_map);
    $baseres->hostname_map($conf->hostnames_map);

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
                       params => \%params,
                       matches => $res->json_output,
                       filters => $facets,
                       filters_needed => $has_facets,
                       pager_needed => $pager->needed,
                       pager => $pager->items,
                       sorter => \@sorter,
                      });
    # Dlog_debug { "json is $_" } $c->stash->{json};
}

sub feed :Chained('/root') :Args(0) {
    my ($self, $c) = @_;
    my $conf = $c->model('DB');
    my $xapian = AmuseWikiFarm::Archive::Xapian->new(multisite => 1,
                                                     stub_database => $conf->stub_database,
                                                    );
    my %params = %{$c->req->params};
    # enforce sorting to be time-based.
    $params{sort} = 'pubdate_desc';
    my $res = $xapian->faceted_search(%params,
                                      published_only => 1,
                                      facets => 0,
                                      filters => 1,
                                     );
    $res->sites_map($conf->site_map);
    my @texts = @{$res->json_output};
    Dlog_debug  { "Matches are $_ " } \@texts;
    my $feed = XML::FeedPP::RSS->new;
    my $my_uri = $c->req->uri;
    $feed->title($my_uri->host);
    $feed->description($my_uri->host);
    $feed->link($c->uri_for_action($c->action));
    $feed->language('en');
    $feed->xmlns('xmlns:atom' => "http://www.w3.org/2005/Atom");
    $feed->set('atom:link@href', $c->uri_for_action($c->action));
    $feed->set('atom:link@rel', 'self');
    $feed->set('atom:link@type', "application/rss+xml");
    if (@texts) {
        $feed->pubDate($texts[0]{pubdate_epoch});
    }
    foreach my $text (@texts) {
        my $item = $feed->add_item($text->{full_uri});
        $item->title(clean_html($text->{title}));
        $item->guid(undef, isPermaLink => 1);
        my @lines;
        foreach my $method (qw/author title subtitle/) {
            if (my $string = $text->{$method}) {
                push @lines,
                  '<strong>' . ucfirst($method) . '</strong>: ' . $string;
            }
        }
        if (my $teaser = $text->{teaser}) {
            push @lines, '<div>' . $teaser . '</div>';
        }
        $item->description('<div>' . join('<br>', @lines) . '</div>');
        $item->pubDate($text->{pubdate_epoch});
    }
    $c->response->content_type('application/rss+xml');
    $c->response->body($feed->to_string);
}


__PACKAGE__->meta->make_immutable;

1;
