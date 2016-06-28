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
    unless ($thumb =~ m/^[0-9a-z][0-9a-z-]*[0-9a-z]\.(pdf|png|jpe?g)\Q$ext\E$/s) {
        log_debug { $thumb . " is not a good name" };
        $c->detach('/not_found');
        return;
    }
    my ($uri) = File::Basename::fileparse($thumb, qr{\Q$ext\E});
    my $srcfile = $c->stash->{site}->attachments->by_uri($uri);
    unless ($srcfile) {
        $c->detach('/not_found');
        return;
    }
    my $thumbdir = File::Spec->rel2abs(File::Spec->catdir('thumbnails',
                                                           $c->stash->{site}->id));

    unless (-d $thumbdir) {
        File::Path::make_path($thumbdir);
    }
    my $src = $srcfile->f_full_path_name;
    unless ($src && -f $src) {
        log_error { "Expected $src file does not exists" };
        $c->detach('/not_found');
        return;
    }
    my $output = File::Spec->catfile($thumbdir, $thumb);
    log_debug { "Checking $output against $src" };
    $self->generate_thumbnail_from_to($src, $output);
    $c->stash(serve_static_file => $output);
    $c->detach($c->view('StaticFile'));
}

sub generate_thumbnail_from_to :Private {
    my ($self, $src, $out) = @_;
    die unless ($src && $out);
    return unless (-f $src);
    return if (-f $out and ((stat($src))[9]) < (stat($out))[9]);
    log_info { "Generating thumbnail from $src to $out" };
    my @exec = (qw/gm convert -thumbnail/);
    if ($src =~ m/\.pdf$/) {
        push @exec, '300x', $src . '[0]', $out;
    }
    else {
        push @exec, '36x', -quality => 50, $src, $out;
    }
    Dlog_info { "Executing $_" } \@exec;
    system(@exec);
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
