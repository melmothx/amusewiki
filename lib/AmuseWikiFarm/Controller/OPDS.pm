package AmuseWikiFarm::Controller::OPDS;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

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
    $feed->updated($c->stash->{site}->last_updated);
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
    my $titles = $c->stash->{site}->titles->published_texts
      ->search(undef, { page => $self->validate_page($page), rows => 5 });
    my $pager = $titles->pager;
    $feed->add_to_navigations_new_level(
                              href => '/opds/titles/' . $pager->current_page,
                              title => $c->loc('Titles'),
                              description => $c->loc('texts sorted by title'),
                              acquisition => 1,
                             );
    $self->add_pagination($feed, $pager, "/opds/titles/", $c->loc('texts sorted by title'));
    while (my $title = $titles->next) {
        if (my $entry = $title->opds_entry) {
            $feed->add_to_acquisitions(%$entry);
        }
    }
    $c->detach($c->view('Atom'));
}

sub new_entries :Chained('root') :PathPart('new') :Args {
    my ($self, $c, $page) = @_;
    my $feed = $c->model('OPDS');
    my $titles = $c->stash->{site}->titles->published_texts
      ->search(undef,
               { page => $self->validate_page($page),
                 rows => 5,
                 order_by => { -desc => 'pubdate' }
               });
    my $pager = $titles->pager;
    $feed->add_to_navigations_new_level(
                                        href => '/opds/new/' . $pager->current_page,
                                        title => $c->loc('Titles'),
                                        description => $c->loc('texts sorted by title'),
                                        acquisition => 1,
                                       );
    $self->add_pagination($feed, $pager, "/opds/new/", $c->loc('texts sorted by title'));
    while (my $title = $titles->next) {
        if (my $entry = $title->opds_entry) {
            $feed->add_to_acquisitions(%$entry);
        }
    }
    $c->detach($c->view('Atom'));
}


sub all_topics :Chained('root') :PathPart('topics') :CaptureArgs(0) {
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
        my $titles = $topic->titles->published_texts
          ->search(undef, { page => $self->validate_page($page), rows => 5 });
        my $pager = $titles->pager;
        $feed->add_to_navigations_new_level(
                                  href => "/opds/topics/$uri/" . $pager->current_page,
                                  title => $c->loc($topic->name),
                                  acquisition => 1,
                                 );
        $self->add_pagination($feed, $pager, "/opds/topics/$uri/", $c->loc($topic->name));
        while (my $title = $titles->next) {
            if (my $entry = $title->opds_entry) {
                $feed->add_to_acquisitions(%$entry);
            }
        }
        $c->detach($c->view('Atom'));
    }
    else {
        $c->detach('/not_found');
    }
}

# and same stuff here
sub all_authors :Chained('root') :PathPart('authors') :CaptureArgs(0) {
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
        my $titles = $author->titles->published_texts
          ->search(undef, { rows => 5, page => $self->validate_page($page) });
        my $pager = $titles->pager;
        $feed->add_to_navigations_new_level(
                                  href => "/opds/authors/$uri/" . $pager->current_page,
                                  title => $author->name,
                                  acquisition => 1,
                                 );
        $self->add_pagination($feed, $pager, "/opds/authors/$uri/", $author->name);
        while (my $title = $titles->next) {
            if (my $entry = $title->opds_entry) {
                $feed->add_to_acquisitions(%$entry);
            }
        }
        $c->detach($c->view('Atom'));
    }
    else {
        $c->detach('/not_found');
    }
}

sub add_pagination :Private {
    my ($self, $feed, $pager, $url_prefix, $desc) = @_;
    die "Bad usage: @_" unless $feed && $pager && $url_prefix && $desc;
    if ($pager->total_entries > $pager->entries_per_page) {
        log_debug { "Adding pagination for page " . $pager->current_page };
        foreach my $ref (qw/first last next previous/) {
            my $pager_method = $ref . '_page';
            if (my $linked_page = $pager->$pager_method) {
                log_debug { "$ref is $linked_page" };
                $feed->add_to_navigations(
                                          rel => $ref,
                                          href => $url_prefix . $linked_page,
                                          description => $desc,
                                          acquisition => 1,
                                         );
            }
            else {
                log_debug { "$ref has no page" };
            }
        }
    }
}

sub validate_page {
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
