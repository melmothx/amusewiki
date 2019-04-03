package AmuseWikiFarm::Controller::Tags;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Tags - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use AmuseWikiFarm::Log::Contextual;

sub root :Chained('/site') :PathPart('tags') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub display :Chained('root') :PathPart('') :Args() {
    my ($self, $c, @args) = @_;

    # The uri part is unique, so in theory we could just look at the
    # last piece. We don't look at what's in between. We could just
    # ignore the pieces in between, or validate the whole path,
    # comparing the path requested with the real path, or redirect if
    # doesn't match. Going for this last option.
    $c->detach('/not_found') unless @args;
    log_debug { "Displaying " . join("/", @args) };
    if (my $target = $c->stash->{site}->tags->find_by_uri($args[-1])) {
        my $full_uri = $target->full_uri;
        my $got = join('/', '', tags => @args);
        log_debug { "$full_uri and $got" };
        if ($full_uri ne $got) {
            $c->response->redirect($c->uri_for($full_uri), 301);
            $c->detach();
            return;
        }
    }
    else {
        log_info { $args[-1] . ' not found'};
        $c->detach('/not_found');
    }
}


=encoding utf8

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
