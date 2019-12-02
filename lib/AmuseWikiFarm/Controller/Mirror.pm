package AmuseWikiFarm::Controller::Mirror;
use Moose;
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';
use namespace::autoclean;

use AmuseWikiFarm::Log::Contextual;
use Path::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Mirror - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site') :PathPart('') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    # this is a bit (just a bit) risky, as we expose the repo tree
    # without doing much checking. However, we don't do directory
    # listing, so the files are accessible only if the path is known.
    # it has the same issues of the /git path, where we expose the
    # tree even if we have not published yet texts. So we do the same
    # check for /git, requiring logging in if not normally exposed.
    $self->check_login($c) if $site->restrict_mirror;
}

sub get_files :Chained('root') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(mirror_file_list => $c->stash->{site}->list_files_for_mirroring);
}

sub mirror_index :Chained('get_files') :PathPart('mirror.txt') :Args(0) {
    my ($self, $c) = @_;
    my $base_url = $c->uri_for_action('/mirror/mirror', '');
    $c->response->content_type('text/plain');
    $c->response->body(join("\n", map { $base_url . $_->{file} } @{$c->stash->{mirror_file_list}}). "\n");
}

sub mirror_index_with_ts :Chained('get_files') :PathPart('mirror.ts.txt') :Args(0) {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain');
    $c->response->body(join("\n", map { $_->{file} . '#' . $_->{ts} } @{$c->stash->{mirror_file_list}}). "\n");
}

sub mirror :Chained('root') :PathPart('mirror') :Args {
    my ($self, $c, @path) = @_;
    Dlog_debug { "Request for under mirror $_" } \@path;
    my $site = $c->stash->{site};
    unless (@path) {
        $c->res->redirect($c->uri_for_action('/mirror/mirror', 'index.html'));
        $c->detach;
        return;
    }

    my %indexes = (
                 'titles.html' => 1,
                 'authors.html' => 1,
                 'topics.html' => 1,
                );
    if (@path == 1 and $indexes{$path[0]}) {
        @path = ('index.html');
    }
    my @valid = grep { m/\A[0-9a-zA-Z_-]+(\.[0-9a-zA-Z]+)*\z/ } @path;
    # all fragments are valid:
    if (scalar(@valid) != scalar(@path)) {
        $c->detach('/bad_request');
        return;
    }
    my $path = path($site->repo_root, @valid);
    if ($path->exists and -f $path) {
        log_debug { "Serving $path" };
        $c->stash(serve_static_file => "$path");
        $c->detach($c->view('StaticFile'));
    }
    else {
        $c->response->status(404);
        $c->response->body("Not found");
        $c->detach;
    }
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
