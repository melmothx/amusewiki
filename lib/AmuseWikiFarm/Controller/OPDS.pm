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

use XML::Atom;
$XML::Atom::DefaultVersion = '1.0';
use XML::Atom::Feed;
use XML::Atom::Link;
use XML::Atom::Entry;
use XML::Atom::Person;
use DateTime;

sub root :Chained('/site') :PathPart('opds') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $feed = XML::Atom::Feed->new;

    my $link = XML::Atom::Link->new;
    $link->type('application/atom+xml;profile=opds-catalog;kind=navigation');
    $link->rel('start');
    $link->href($c->uri_for_action('/opds/start'));
    $feed->add_link($link);

    my $generator = XML::Atom::Person->new;
    $generator->name('amusewiki');
    $generator->uri('http://amusewiki.org');
    $feed->author($generator);

    # the timestamp
    $feed->updated($c->stash->{site}->last_updated);
    $c->stash(feed => $feed);
}

sub start :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $feed = $c->stash->{feed};
    my $self_link = $c->request->uri;
    $feed->id($self_link);
    $feed->title('OPDS');

    my $link = XML::Atom::Link->new;
    $link->type('application/atom+xml;profile=opds-catalog;kind=navigation');
    $link->rel('self');
    $link->href($self_link);
    $feed->add_link($link);

    foreach my $entry ({
                        link => $c->uri_for_action('/opds/titles'),
                        title => $c->loc('Titles'),
                        desc => $c->loc('texts sorted by title'),
                        leaf => 1,
                       },
                       {
                        link => $c->uri_for_action('/opds/topics'),
                        title => $c->loc('Topics'),
                        desc => $c->loc('texts sorted by topics'),
                       },
                       {
                        link => $c->uri_for_action('/opds/authors'),
                        title => $c->loc('Authors'),
                        desc => $c->loc('texts sorted by author'),
                       }) {
        my $item = XML::Atom::Entry->new;
        # my $link = XML::Atom::Link->new;
        $item->title($entry->{title});
        $item->id($entry->{link});
        $item->content($entry->{desc});
        $item->updated(DateTime->now);
        my $link = XML::Atom::Link->new;
        $link->rel('subsection');
        $link->href($entry->{link});
        my $kind = $entry->{leaf} ? 'acquisition' : 'navigation';
        $link->type("application/atom+xml;profile=opds-catalog;kind=$kind");
        $item->add_link($link);
        $feed->add_entry($item);
    }
    $c->detach($c->view('Atom'));
}

sub titles :Chained('root') :PathPart('titles') :Args {
    my ($self, $c, $page) = @_;
    $page ||= 1;
    # this is an acquisition feed
    # Every OPDS Catalog Feed Document MUST either be an Acquisition Feed or a
    # Navigation Feed. An Acquisition Feed can be identified by the presence of
    # Acquisition Links in each Atom Entry.

    my $titles = $c->stash->{site}->titles->published_texts;
    my $feed = $c->stash->{feed};
    $feed->id($c->request->uri);
    $feed->title($c->loc('texts sorted by title'));
    foreach my $nav ({
                      rel => 'self',
                      href => $c->request->uri,
                      leaf => 1,
                     },
                     {
                      rel => 'up',
                      href => $c->uri_for_action('/opds/start'),
                     }) {
        my $link = XML::Atom::Link->new;
        $link->rel($nav->{rel});
        $link->href($nav->{href});
        my $kind = $nav->{leaf} ? 'acquisition' : 'navigation';
        $link->type("application/atom+xml;profile=opds-catalog;kind=$kind");
        $feed->add_link($link);
    }
    my $prefix = $c->uri_for('/');
    while (my $title = $titles->next) {
        if (my $entry = $title->opds_entry) {
            $feed->add_entry($self->_create_title_entry($prefix, $entry));
        }
    }
    $c->detach($c->view('Atom'));
}

sub topics :Chained('root') :PathPart('topics') :Args {
    my ($self, $c) = @_;
}

sub authors :Chained('root') :PathPart('authors') :Args {
    my ($self, $c) = @_;
}

sub _create_title_entry {
    my ($self, $prefix, $data) = @_;
    # data expects an hashref with title, updated, full_uri, epub, lang, author, content
    Dlog_debug { "Data for title entry is $_" } $data;
    $prefix ||= '';
    my $entry = XML::Atom::Entry->new;
    $entry->id($prefix . $data->{full_uri});
    $entry->title($data->{title});
    $entry->updated($data->{updated});
    my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
    $entry->set($dc, 'language', $data->{lang});
    # save the query and make it simple, those applications are
    # crappy anyway
    if (my $author = $data->{author}) {
        my $author_obj = XML::Atom::Person->new;
        $author_obj->name($author);
        $entry->add_author($author_obj);
    }
    $entry->content($data->{content});
    my $link = XML::Atom::Link->new;
    $link->rel('http://opds-spec.org/acquisition/open-access');
    $link->href($prefix . $data->{epub});
    $link->type('application/epub+zip');
    $entry->add_link($link);
    return $entry;
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
