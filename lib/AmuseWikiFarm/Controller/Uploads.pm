package AmuseWikiFarm::Controller::Uploads;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Uploads - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 root

Start of chaing with /uploads/<site_id> and validate the site id.

=cut

use File::Basename ();
use File::Path ();
use File::Spec;
use IO::File;

sub root :Chained('/site') :PathPart('uploads') :CaptureArgs(1) {
    my ( $self, $c, $site_id ) = @_;
    if ($site_id ne $c->stash->{site}->id) {
        $c->detach('/not_found');
    }
}

sub upload :Chained('root') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    my $attachment = $c->stash->{site}->attachments->pdf_by_uri($uri);

    log_debug { "Trying to serve $uri "};
    if ($attachment) {
        $c->stash(
                  serve_static_file => $attachment->f_full_path_name,
                  attachment_uri => $uri,
                 );
    }
    else {
        $c->detach('/not_found');
    }
}

sub pdf :Chained('upload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->detach($c->view('StaticFile'));
}

sub thumbnail :Chained('root') :PathPart('thumbnails') :Args(1) {
    my ($self, $c, $thumb) = @_;
    log_debug { "Looking up $thumb" };
    my $site = $c->stash->{site};
    # if the DB is compromised, we're fried anyway
    if (my $thumb = $site->thumbnails->find({ file_name => $thumb })) {
        $c->stash(serve_static_file => $thumb->file_path);
        $c->detach($c->view('StaticFile'));
    }
    else {
        $c->detach('/not_found');
    }
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
