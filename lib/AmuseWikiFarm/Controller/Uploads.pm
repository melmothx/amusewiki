package AmuseWikiFarm::Controller::Uploads;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

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
use IO::File;

sub root :Chained('/') :PathPart('uploads') :CaptureArgs(1) {
    my ( $self, $c, $site_id ) = @_;
    if ($site_id ne $c->stash->{site}->id) {
        $c->detach('/not_found');
    }
}

sub upload :Chained('root') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    my $attachment = $c->stash->{site}->attachments->pdf_by_uri($uri);

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

# this should be touched only when thumbnails does not exist

sub thumbnail :Chained('root') :PathPart('thumbnails') :Args(1) {
    my ($self, $c, $thumb) = @_;
    my $ext = '.thumb.png';
    # paranoid check
    unless ($thumb =~ m/^[0-9a-z][0-9a-z-]*[0-9a-z]\.pdf\Q$ext\E$/s) {
        $c->detach('/not_found');
        return;
    }
    my ($uri) = File::Basename::fileparse($thumb, $ext);
    my $srcfile = $c->stash->{site}->attachments->pdf_by_uri($uri);
    unless ($srcfile) {
        $c->detach('/not_found');
        return;
    }
    my @basedir = ('root', 'uploads', $c->stash->{site}->id,
                     'thumbnails');
    my $dir = $c->path_to(@basedir)->stringify;
    unless (-d $dir) {
        File::Path::make_path($dir);
    }

    my $src = $srcfile->f_full_path_name;
    unless ($src && -f $src) {
        $c->log->error("Expected $src file does not exists");
        $c->detach('/not_found');
        return;
    }

    my $output = $c->path_to(@basedir, $thumb);

    $c->log->warn("Generating thumbnail from $src to $output");
    $self->generate_thumbnail_from_to($src, $output);
    if (-f $output) {
        my $fh = IO::File->new($output, 'r');
        $c->response->body($fh);
        $c->response->headers->content_type('image/png');
        $c->response->headers->content_length(-s $output);
        $c->response->headers->last_modified((stat($output))[9]);
    }
    else {
        $c->detach('/not_found');
        return;
    }
}

sub generate_thumbnail_from_to :Private {
    my ($self, $src, $out) = @_;
    die unless ($src && $out);
    return unless (-f $src);
    return if (-f $out and ((stat($src))[9]) < (stat($out))[9]);
    system('gm', 'convert', '-thumbnail', 'x300', $src . '[0]', $out);
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
