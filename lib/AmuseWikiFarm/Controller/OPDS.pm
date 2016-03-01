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
use XML::Atom::Feed;
use XML::Atom::Link;
use XML::Atom::Entry;
use XML::Atom::Person;
use DateTime;
$XML::Atom::DefaultVersion = '1.0';


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
    $c->response->content_type($feed->content_type);
    $c->response->body($feed->as_xml);
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

    while (my $title = $titles->next) {
        next unless $title->check_if_file_exists('epub');

        # mandatory: id, updated , title
        my $entry = XML::Atom::Entry->new;

        # Following Atom [RFC4287] Section 4.2.6, the content of an
        # "atom:id" identifying an OPDS Catalog Entry MUST NOT change
        # when the OPDS Catalog Entry is "relocated, migrated,
        # syndicated, republished, exported, or imported" and "MUST be
        # created in a way that assures uniqueness."
        # .... go figure

        my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
        $entry->set($dc, 'language', $title->lang);
        foreach ($title->authors) {
            my $author = XML::Atom::Person->new;
            $author->name($_->name);
            $author->uri($c->uri_for($_->full_uri));
            $entry->add_author($author);
        }
        $entry->title($title->title);

        $entry->id($c->uri_for($title->full_uri));
        $entry->updated($title->pubdate);


        my @desc;
        foreach my $method (qw/author title subtitle date notes source/) {
            my $string = $title->$method;
            if (length($string)) {
                push @desc,
                  '<h4>' . $c->loc(ucfirst($method)) . '</h4><div>' . $string . '</div>';
            }
        }
        $entry->content(join("\n", @desc));

        my $link = XML::Atom::Link->new;
        $link->rel('http://opds-spec.org/acquisition/open-access');
        $link->href($c->uri_for($title->full_uri) . '.epub');
        $link->type('application/epub+zip');
        $entry->add_link($link);
        $feed->add_entry($entry);
    }
    $c->response->content_type($feed->content_type);
    $c->response->body($feed->as_xml);
}

sub topics :Chained('root') :PathPart('topics') :Args {
    my ($self, $c) = @_;
}

sub authors :Chained('root') :PathPart('authors') :Args {
    my ($self, $c) = @_;
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
