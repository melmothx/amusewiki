package AmuseWikiFarm::View::Atom;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Encode;
use AmuseWikiFarm::Log::Contextual;

sub process {
    my ($self, $c) = @_;
    if (my $feed = $c->model('OPDS')->atom) {
        $c->response->content_type($feed->content_type);
        # this is a waste, with catalyst trying to be too smart
        $c->response->body(Encode::decode('UTF-8', $feed->as_xml));
    }
    else {
        Dlog_error { "Stash is $_ forwarded to Atom view!" } $c->stash;
        $c->detach('/not_found');
    }
}

__PACKAGE__->meta->make_immutable;

1;
