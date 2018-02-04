package TestApp::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

use AmuseWikiFarm::Log::Contextual;

__PACKAGE__->config(namespace => '');

sub auto :Private {
    my ($self, $c) = @_;
    my $host = $c->request->uri->host;
    # lookup in the db: first the canonical, then the vhosts
    log_debug { "Looking up $host" };
    my $site = $c->model('DBICSchema::Site')->find({ canonical => $host });
    $c->stash(site => $site);
    return 1;
}

1;
