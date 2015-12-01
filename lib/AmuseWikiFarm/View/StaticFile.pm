package AmuseWikiFarm::View::StaticFile;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Plack::Util;
use AmuseWikiFarm::Log::Contextual;

sub process {
    my ($self, $c) = @_;
    my $file = $c->stash->{serve_static_file};
    log_debug { "Serving $file" };
    unless ($file and -f $file) {
        log_error { "$file is not a file!" };
        $c->detach('/not_found');
        return;
    }
    my $mime = {
                tex => 'application/x-tex',
                pdf => 'application/pdf',
                html => 'text/html',
                epub => 'application/epub+zip',
                muse => 'text/plain',
                zip => 'application/zip',
                png => 'image/png',
                jpg => 'image/jpeg',
                jpeg => 'image/jpeg',
                ico => 'image/x-icon',
                css => 'text/css',
                js => 'text/javascript',
               };

    # no extension => octect-stream
    my $type = 'application/octet-stream';
    if ($file =~ m/\.(\w+)$/) {
        $type = $mime->{$1} || 'text/plain';
    }

    my $fh = IO::File->new($file, 'r');
    Plack::Util::set_io_path($fh, $file);
    # or
    # my $fh = IO::File::WithPath->new($file, 'r');
    if ($type eq 'text/plain') {
        $type .= '; charset=UTF-8';
    }
    $c->response->headers->content_type($type);
    $c->response->headers->content_length(-s $file);
    $c->response->headers->last_modified((stat($file))[9]);
    $c->response->body($fh);
}

__PACKAGE__->meta->make_immutable;

1;

