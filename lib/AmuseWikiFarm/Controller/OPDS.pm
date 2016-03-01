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

    $feed->updated(DateTime->now);
    foreach my $entry ({
                        link => $c->uri_for_action('/opds/titles'),
                        title => $c->loc('Titles'),
                        desc => $c->loc('texts sorted by title'),
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
        $link->type("application/atom+xml;profile=opds-catalog;kind=navigation");
        $item->add_link($link);
        $feed->add_entry($item);
    }
    $c->response->content_type($feed->content_type);
    $c->response->body($feed->as_xml);
}

sub titles :Chained('root') :PathPart('titles') :Args {
    my ($self, $c) = @_;
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
