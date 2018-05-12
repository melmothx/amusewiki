package AmuseWikiFarm::Controller::OPDS;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use DateTime;
use AmuseWikiFarm::Utils::Amuse qw/clean_html/;

=head1 NAME

AmuseWikiFarm::Controller::OPDS - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 root

=cut

sub root :Chained('/site') :PathPart('opds') :CaptureArgs(0) {
    my ($self, $c) = @_;
    # pick the model and stash it.
    my $feed = $c->model('OPDS');
    my $prefix = $c->uri_for('/')->as_string;
    $prefix =~ s!/$!!;
    $feed->prefix($prefix);

    # add the favicon
    if ($c->stash->{site}->has_site_file('favicon.ico')) {
        $feed->icon('/favicon.ico');
    }
    $feed->updated($c->stash->{site}->last_updated || DateTime->now);
    $feed->author($c->stash->{site}->sitename);
    $feed->author_uri($prefix);
    my %start = (
                 title => $c->stash->{site}->sitename,
                 href => '/opds',
                );
    # populate the feed with the root
    $feed->add_to_navigations_new_level(%start);
    $start{rel} = 'start';
    $feed->add_to_navigations(%start);
    foreach my $entry ({
                        href => '/opds/titles',
                        title => $c->loc('Titles'),
                        description => $c->loc('texts sorted by title'),
                        acquisition => 1,
                       },
                       {
                        href => '/opds/topics',
                        title => $c->loc('Topics'),
                        description => $c->loc('texts sorted by topics'),
                       },
                       {
                        href => '/opds/authors',
                        title => $c->loc('Authors'),
                        description => $c->loc('texts sorted by author'),
                       },
                       {
                        href => '/opds/new',
                        title => $c->loc('New'),
                        description => $c->loc('Latest entries'),
                        rel => 'new',
                        acquisition => 1,
                       },
                       {
                        href => '/opds/crawlable',
                        title => $c->loc('Titles'),
                        description => 'Crawlable full catalog for robots',
                        rel => 'crawlable',
                        acquisition => 1,
                       },
                       {
                        href => $c->uri_for_action('/search/opensearch')->path,
                        title => $c->loc('Search'),
                        rel => 'search',
                       },
                      ) {
        $feed->add_to_navigations(%$entry);
    }
}

sub start :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->detach($c->view('Atom'));
}

sub titles :Chained('root') :PathPart('titles') :Args {
    my ($self, $c, $page) = @_;
    my $feed = $c->model('OPDS');
    my $titles = $c->stash->{site}->titles->published_texts;
    if ($self->populate_acquistions($feed, '/opds/titles/',  $c->loc('Titles'), $titles, $page)) {
        $c->detach($c->view('Atom'));
    }
    else {
        $c->detach('/not_found');
    }

}

sub new_entries :Chained('root') :PathPart('new') :Args {
    my ($self, $c, $page) = @_;
    my $feed = $c->model('OPDS');
    my $titles = $c->stash->{site}->titles->published_texts->sort_by_pubdate_desc;
    if ($self->populate_acquistions($feed, '/opds/new/',  $c->loc('Latest entries'), $titles, $page)) {
        $c->detach($c->view('Atom'));
    }
    else {
        $c->detach('/not_found');
    }
}

sub clean_root :Chained('root') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $feed = $c->model('OPDS');
    # remove the new from leaves navigations
    my @navs = grep { $_->rel ne 'new' } @{$feed->navigations};
    $feed->navigations(\@navs);
}

sub all_topics :Chained('clean_root') :PathPart('topics') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $topics = $c->stash->{site}->categories->active_only_by_type('topic');
    $c->stash(feed_rs => $topics);
    my $feed = $c->model('OPDS');
    $feed->add_to_navigations_new_level(
                              href => '/opds/topics',
                              title => $c->loc('Topics'),
                              description => $c->loc('texts sorted by topics'),
                             );
}

sub topics :Chained('all_topics') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $topics = $c->stash->{feed_rs};
    my $feed = $c->model('OPDS');
    while (my $topic = $topics->next) {
        $feed->add_to_navigations(
                                  href => '/opds/topics/' . $topic->uri,
                                  title => $c->loc($topic->name),
                                  acquisition => 1,
                                 )
    }
    $c->detach($c->view('Atom'));
}

sub topic :Chained('all_topics') :PathPart('') :Args {
    my ($self, $c, $uri, $page) = @_;
    die "shouldn't happen" unless $uri;
    my $topics = $c->stash->{feed_rs};
    if (my $topic = $topics->find({ uri => $uri })) {
        my $feed = $c->model('OPDS');
        my $titles = $topic->titles->published_texts;
        if ($self->populate_acquistions($feed, "/opds/topics/$uri/", $c->loc($topic->name), $titles, $page)) {
            $c->detach($c->view('Atom'));
            return;
        }
    }
    $c->detach('/not_found');
}

# and same stuff here
sub all_authors :Chained('clean_root') :PathPart('authors') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $authors = $c->stash->{site}->categories->active_only_by_type('author');
    $c->stash(feed_rs => $authors);
    my $feed = $c->model('OPDS');
    $feed->add_to_navigations_new_level(
                              href => '/opds/authors',
                              title => $c->loc('Authors'),
                              description => $c->loc('texts sorted by author'),
                             );
}

sub authors :Chained('all_authors') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $authors = $c->stash->{feed_rs};
    my $feed = $c->model('OPDS');
    while (my $author = $authors->next) {
        $feed->add_to_navigations(
                                  href => '/opds/authors/' . $author->uri,
                                  title => $author->name,
                                  acquisition => 1,
                                 );
    }
    $c->detach($c->view('Atom'));
}

sub author :Chained('all_authors') :PathPart('') :Args {
    my ($self, $c, $uri, $page) = @_;
    die "shouldn't happen" unless $uri;
    my $authors = $c->stash->{feed_rs};
    if (my $author = $authors->find({ uri => $uri })) {
        my $feed = $c->model('OPDS');
        my $titles = $author->titles->published_texts;
        if ($self->populate_acquistions($feed, "/opds/authors/$uri/", $author->name, $titles, $page)) {
            $c->detach($c->view('Atom'));
        }
    }
    $c->detach('/not_found');
}

sub search :Chained('clean_root') :PathPart('search') :Args(0) {
    my ($self, $c) = @_;
    my $feed = $c->model('OPDS');
    my $site = $c->stash->{site};
    my $xapian = $site->xapian;
    my $query = $c->request->params->{query} // '';
    my $page = $self->validate_page($c->request->params->{page});
    my $base = $c->uri_for($c->action, { query => $query })->path_query . '&page=';
    $feed->add_to_navigations_new_level(
                                        acquisition => 1,
                                        href => $base . $page,
                                        title => $c->loc('Search results'),
                                        description => $c->loc('texts sorted by author'),
                                       );
    if ($query) {
        my $res = $xapian->faceted_search(facets => 0,
                                          page => $page,
                                          locale => $c->stash->{current_locale_code},
                                          query => $query);
        if (my @results = @{$res->matches}) {
            my $pager = $res->pager;
            $feed->search_result_pager($pager);
            $feed->search_result_terms($query);
            $self->add_pager($feed, $pager, $base, $c->loc('Search results'));
            foreach my $match (@results) {
                if (my $title = $site->titles->text_by_uri($match->{pagedata}->{uri})) {
                    if (my $entry = $title->opds_entry) {
                        $feed->add_to_acquisitions(%$entry);
                    }
                }
            }
        }
    }
    $c->detach($c->view('Atom'));
}

sub crawlable :Chained('clean_root') :PathPart('crawlable') :Args(0) {
    my ($self, $c) = @_;
    my $feed = $c->model('OPDS');
    my $site = $c->stash->{site};
    $feed->add_to_navigations_new_level(
                                        acquisition => 1,
                                        href => '/opds/crawlable',
                                        title => $c->loc('Titles'),
                                        description => $c->loc('texts sorted by title'),
                                       );
    # This is as much optimized as it can get. The bottleneck now is
    # in the XML generation, and there is nothing to do, I think.
    my $time = my $now = time();
    my @texts = $site->titles->published_texts->sorted_by_title
      ->search(undef,
               {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                collapse => 1,
                join => { title_categories => 'category' },
                columns => [qw/me.uri
                               me.title
                               me.lang
                               me.date
                               me.pubdate
                               me.subtitle
                              /],,
                '+columns' => {
                               'title_categories.title_id' => 'title_categories.title_id',
                               'title_categories.category_id' => 'title_categories.category_id',
                               'title_categories.category.uri' => 'category.uri',
                               'title_categories.category.type' => 'category.type',
                               'title_categories.category.name' => 'category.name',
                              }
               })->all;
    my $dt_parser = $c->model('DB')->storage->datetime_parser;
    # Dlog_debug { "texts: $_" } [ \@texts, $c->model('DB')->storage->datetime_parser ];
    log_debug { $now = time();
                my $elapsed = $now - $time;
                $time = $now;
                "query done in $elapsed seconds" };
    while (@texts) {
        my $text = shift @texts;
        my %entry = (
                     title => clean_html($text->{title}),
                     href => '/library/' . $text->{uri},
                     epub => '/library/' . $text->{uri} . '.epub',
                     language => $text->{lang} || 'en',
                     issued => $text->{date} || '',
                     summary => clean_html($text->{subtitle}),
                     files => [ '/library/' . $text->{uri} . '.epub', ],
                    );
        if ($text->{pubdate}) {
            $entry{updated} = $dt_parser->parse_datetime($text->{pubdate});
        }
        if (my $cats = $text->{title_categories}) {
            foreach my $cat (@$cats) {
                if (my $category = $cat->{category}) {
                    if ($category->{type} eq 'author') {
                        $entry{authors} ||= [];
                        push @{$entry{authors}}, {
                                                  name => $category->{name},
                                                  uri => '/category/author/' . $category->{uri},
                                                 };
                    }
                }
            }
        }
        $feed->add_to_acquisitions(%entry);
    }
    log_debug { $now = time();
                my $elapsed = $now - $time;
                $time = $now;
                "parsing done in $elapsed seconds" };
    $c->detach($c->view('Atom'));
}

sub add_pager :Private {
    my ($self, $feed, $pager, $base, $description) = @_;
    if ($pager->current_page > $pager->last_page) {
        return;
    }
    if ($pager->total_entries > $pager->entries_per_page) {
        log_debug { "Adding pagination for page " . $pager->current_page };
        foreach my $ref (qw/first last next previous/) {
            my $pager_method = $ref . '_page';
            if (my $linked_page = $pager->$pager_method) {
                log_debug { "$ref is $linked_page" };
                $feed->add_to_navigations(
                                          rel => $ref,
                                          href => $base . $linked_page,
                                          description => $description,
                                          acquisition => 1,
                                         );
            }
            else {
                log_debug { "$ref has no page" };
            }
        }
    }
}

sub populate_acquistions :Private {
    my ($self, $feed, $base, $description, $rs, $page) = @_;
    die unless ($feed && $base && $description && $rs);
    # this is a dbic search
    my $titles = $rs->search(undef, { page => $self->validate_page($page), rows => 5 });
    my $pager = $titles->pager;
    $feed->add_to_navigations_new_level(
                                        href => $base . $pager->current_page,
                                        title => $description,
                                        acquisition => 1,
                                       );
    $self->add_pager($feed, $pager, $base, $description);
    my $return = 0;
    while (my $title = $titles->next) {
        if (my $entry = $title->opds_entry) {
            $feed->add_to_acquisitions(%$entry);
            $return++;
        }
    }
    return $return;
}

sub validate_page :Private {
    my ($self, $page) = @_;
    my $valid = 1;
    if ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $valid = $page;
    }
    return $valid;
}


=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
