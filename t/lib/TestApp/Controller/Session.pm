package TestApp::Controller::Session;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

sub setup : Local {
    my ($self, $c) = @_;

    my $key   = $c->req->param('key')   || 'key';
    my $value = $c->req->param('value') || 1;

    $c->session->{$key} = $value;
    $c->res->body('ok');
}

sub output : Local {
    my ($self, $c) = @_;

    my $key = $c->req->param('key') || 'key';

    $c->res->body($c->session->{$key});
}

sub delete : Local {
    my ($self, $c) = @_;

    $c->delete_session;
    $c->res->body($c->session_is_valid ? 'not ok' : 'ok');
}

sub delete_expired : Local {
    my ($self, $c) = @_;

    $c->delete_expired_sessions;
    $c->res->body('ok');
}

1;
