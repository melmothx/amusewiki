package AmuseWikiFarm::Controller::Feed;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Feed - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index

Path: /feed

RSS 2.0 feed, built using XML::FeedPP

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    my @texts = $site->titles->latest;

    my @specials = $site->titles->published_specials;

    my $feed = $c->model('Feed');

    # set up the channel
    $feed->title($site->sitename);
    $feed->description($site->siteslogan);

    $feed->link($site->canonical_url);
    $feed->language($site->locale);

    $feed->xmlns('xmlns:atom' => "http://www.w3.org/2005/Atom");

    # set the link to ourself
    $feed->set('atom:link@href', $c->uri_for_action($c->action));
    $feed->set('atom:link@rel', 'self');
    $feed->set('atom:link@type', "application/rss+xml");

    if (@texts) {
        $feed->pubDate($texts[0]->pubdate->epoch);
    }

    foreach my $text (@specials, @texts) {
        my $link;
        if ($text->f_class eq 'text') {
            $link = $c->uri_for_action('/library/text', [$text->uri]);
        }
        else {
            # to fool the scrapers, set the permalink for specials
            # adding a version with the timestamp of the file, so we
            # catch updates
            $link = $c->uri_for_action('/library/special', [$text->uri],
                                       { v => $text->f_timestamp_epoch });
        }

        # here we must force stringification
        my $item = $feed->add_item("$link");
        $item->title($text->title);
        $item->pubDate($text->pubdate->epoch);
        $item->guid(undef, isPermaLink => 1);

        if ($text->f_class eq 'special') {
            my $body = $text->html_body;
            $item->description($body);
            next;
        }
        my @lines;
        foreach my $method (qw/author title subtitle date notes source/) {
            my $string = $text->$method;
            if (length($string)) {
                push @lines,
                  '<strong>' . $c->loc(ucfirst($method)) . '</strong>: ' . $string;
            }
        }
        $item->description('<div>' . join('<br>', @lines) . '</div>');

        # if we provide epub, add it as attachment, so the poor
        # bastards with phones can actually read something.
        if ($site->epub) {
            my $epub_local_file = $text->filepath_for_ext('epub');
            if (-f $epub_local_file) {
                my $epub_url = $c->uri_for_action('/library/text',
                                                  [ $text->uri . '.epub' ]);
                $c->log->debug("EPUB path = $epub_local_file");
                $item->set('enclosure@url' => $epub_url);
                $item->set('enclosure@type' => 'application/epub+zip');
                $item->set('enclosure@length' => -s $epub_local_file);
            }
        }
    }

    # render and set
    $c->response->content_type('application/rss+xml');
    $c->response->body($feed->to_string);
}

=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
