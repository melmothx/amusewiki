package AmuseWikiMeta::View::Atom;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Encode;
use AmuseWikiFarm::Log::Contextual;

sub process {
    my ($self, $c) = @_;
    if (my $feed = $c->model('OPDS')->atom) {
        $c->response->content_type($feed->content_type);
        $c->clear_encoding;
        $c->response->body($feed->as_xml);
    }
    else {
        Dlog_error { "Stash is $_ forwarded to Atom view!" } $c->stash;
        $c->response->content_type('text/plain');
        $c->response->body('Not found');
        $c->response->status(404);
    }
}

__PACKAGE__->meta->make_immutable;

1;
