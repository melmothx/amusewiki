package AmuseWikiMeta::Controller::OPDS;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::Xapian;
use AmuseWikiFarm::Utils::Paginator;
use AmuseWikiFarm::Utils::Amuse qw/clean_html/;
use Template::Tiny;

sub opensearch :Chained('/root') :PathPart('opensearch.xml') :Args(0) {
    my ($self, $c) = @_;
    $c->res->content_type('application/xml');
    my $tmpl =<<"XML";
<?xml version="1.0" encoding="UTF-8" ?>
<!-- See http://www.opensearch.org/Specifications/OpenSearch/1.1 -->
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>[% name %]</ShortName>
  <Description>[% description %]</Description>
  <InputEncoding>UTF-8</InputEncoding>
  <OutputEncoding>UTF-8</OutputEncoding>
  <AdultContent>[% IF adult_content %]true[% ELSE %]false[% END %]</AdultContent>
  [% FOREACH lang IN languages %]<Language>[% lang %]</Language>[% END %]
  <SyndicationRight>[% IF is_private %]limited[% ELSE %]open[% END %]</SyndicationRight>
  [% IF icon_url %]<Image type="image/x-icon">[% icon_url %]</Image>[% END %]
  <Url type="text/html" template="[% search_html %]" />
  <Url type="application/atom+xml;profile=opds-catalog"
       xmlns:atom="http://www.w3.org/2005/Atom"
       template="[% search_opds %]" />
</OpenSearchDescription>
XML
    my $xml;
    Template::Tiny->new->process(\$tmpl, {
                                          %{ $c->model('DB')->meta_info },
                                          search_html => $c->uri_for_action('/pages', [])   . '?query={searchTerms}',
                                          search_opds => $c->uri_for_action('/opds/search') . '?query={searchTerms}',
                                         }, \$xml);
    $c->res->body($xml);
}


sub opds :Chained('/root') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $feed = $c->model('OPDS');
    my $meta = $c->model('DB')->meta_info;
    if ($meta->{icon_url}) {
        $feed->icon($meta->{icon_url});
    }
    $feed->author($meta->{name});
    $feed->author_uri($c->uri_for_action('/pages', [])->as_string);
    my %start = (
                 title => $meta->{name},
                 href => $c->uri_for_action('/opds/start')->as_string,
                );
    # populate the feed with the root
    $feed->add_to_navigations_new_level(%start);
    $start{rel} = 'start';
    $feed->add_to_navigations(%start);
    foreach my $entry (
                       {
                        href => $c->uri_for_action('/opds/opensearch')->as_string,
                        title => 'Search',
                        rel => 'search',
                       },
                      ) {
        $feed->add_to_navigations(%$entry);
    }
}

sub start :Chained('opds') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->model('OPDS')->add_to_navigations(
                                          href => $c->uri_for_action('/opds/new_entries')->as_string,
                                          title => 'New',
                                          description => 'Latest entries',
                                          rel => 'new',
                                          acquisition => 1,
                                         );
    $c->detach($c->view('Atom'));
}

sub search :Chained('opds') :PathPart('search') :Args(0) {
    my ($self, $c) = @_;
    my $query = $c->req->params->{query};
    my $page = $c->req->params->{page};
    my $build_uri = sub {
        my $p = shift;
        return $c->uri_for($c->action, {
                                        query => $query,
                                        page => $p,
                                       })->as_string;
    };
    $self->populate(feed => $c->model('OPDS'),
                    config => $c->model('DB'),
                    params => {
                               query => $query,
                               page => $page,
                              },
                    build_uri => $build_uri,
                    title => "Search results",
                    description => "Search results",
                   );
    $c->detach($c->view('Atom'));
}

sub new_entries :Chained('opds') :PathPart('new') :Args {
    my ($self, $c, $page) = @_;
    my $build_uri = sub {
        my $p = shift;
        return $c->uri_for($c->action, $p)->as_string;
    };
    $self->populate(feed => $c->model('OPDS'),
                    config => $c->model('DB'),
                    params => {
                               page => $page,
                               sort => 'pubdate_desc'
                              },
                    build_uri => $build_uri,
                    title => "New titles",
                    description => "Latest entries",
                   );
    $c->detach($c->view('Atom'));
}


sub populate {
    my ($self, %args) = @_;
    my $feed = $args{feed};
    my $conf = $args{config};
    my $page = $args{params}{page};
    if ($page and $page =~ m/\A([1-9][0-9]*)\z/) {
        $page = $1;
    }
    else {
        $page = 1;
    }
    $args{params}{page} = $page;
    my $xapian = AmuseWikiFarm::Archive::Xapian->new(multisite => 1,
                                                     stub_database => $conf->stub_database,
                                                    );
    my $res = $xapian->faceted_search(
                                      %{ $args{params} },
                                      facets => 0,
                                      filters => 0,
                                     );
    $res->sites_map($conf->site_map);
    my @texts = @{$res->json_output};
    Dlog_debug  { "Matches are $_ " } \@texts;
    my $pager = $res->pager;
    if (my $query = $args{params}{query}) {
        $feed->search_result_pager($pager);
        $feed->search_result_terms($query);
    }
    $feed->add_to_navigations_new_level(
                                        href => $args{build_uri}->($page),
                                        acquisition => 1,
                                        title => $args{title},
                                        description => $args{description},
                                       );
    foreach my $text (@texts) {
        if ($text->{title}) {
            $feed->add_to_acquisitions(
                                       href => $text->{full_uri},
                                       title => clean_html($text->{title}),
                                       description => $text->{feed_teaser} || $text->{title},
                                       language => $text->{lang},
                                       issued => $text->{pubdate_iso},
                                       $text->{author} ? (authors => [ clean_html($text->{author}) ]) : (),
                                       files => [ $text->{full_uri} . '.epub' ],
                                      );
        }
    }
    if ($pager->current_page <= $pager->last_page) {
        if ($pager->total_entries > $pager->entries_per_page) {
            log_debug { "Adding pagination for page " . $pager->current_page };
            foreach my $ref (qw/first last next previous/) {
                my $pager_method = $ref . '_page';
                if (my $linked_page = $pager->$pager_method) {
                    log_debug { "$ref is $linked_page" };
                    $feed->add_to_navigations(
                                              rel => $ref,
                                              href => $args{build_uri}->($linked_page),
                                              acquisition => 1,
                                              title => $args{title},
                                              description => $args{description},
                                             );
                }
                else {
                    log_debug { "$ref has no page" };
                }
            }
        }
    }
}


__PACKAGE__->meta->make_immutable;

1;
