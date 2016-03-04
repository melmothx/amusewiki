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
    my %start = (
                 rel => 'self',
                 title => $c->stash->{site}->sitename,
                 href => '/opds',
                 updated => $c->stash->{site}->last_updated,
                );
    # populate the feed with the root
    $feed->add_to_navigations(%start);
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
                       }) {
        $feed->add_to_navigations(%$entry);
    }
}

sub start :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->detach($c->view('Atom'));
}

sub titles :Chained('root') :PathPart('titles') :Args {
    my ($self, $c, $page) = @_;
    $page ||= 1;
    my $feed = $c->model('OPDS');
    my $titles = $c->stash->{site}->titles->published_texts;
    $feed->add_to_navigations(
                              rel => 'self',
                              href => '/opds/titles',
                              title => $c->loc('Titles'),
                              description => $c->loc('texts sorted by title'),
                              acquisition => 1,
                             );
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
    $feed->add_to_navigations(
                              rel => 'self',
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

sub topic :Chained('all_topics') :PathPart('') :Args(1) {
    my ($self, $c, $uri) = @_;
    my $topics = $c->stash->{feed_rs};
    if (my $topic = $topics->find({ uri => $uri })) {
        my $feed = $c->model('OPDS');
        $feed->add_to_navigations(
                                  rel => 'self',
                                  href => "/opds/topics/$uri",
                                  title => $c->loc($topic->name),
                                  acquisition => 1,
                                 );
        my $titles = $topic->titles->published_texts;
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


sub all_authors :Chained('root') :PathPart('authors') {
}

sub authors :Chained('all_authors') :PathPart('authors') :Args {
    my ($self, $c) = @_;
    $c->detach($c->view('Atom'));
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
