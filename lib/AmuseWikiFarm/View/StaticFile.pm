package AmuseWikiFarm::View::StaticFile;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Plack::Util;
use AmuseWikiFarm::Log::Contextual;
use Path::Tiny ();
use Cwd;
use constant ROOT => getcwd();

sub process {
    my ($self, $c) = @_;
    my $file = $c->stash->{serve_static_file};
    log_debug { "Serving $file" };
    unless ($file and -f $file and ! -l $file) {
        log_error { "$file is not a file! (symlink maybe)" };
        $c->response->status(404);
        $c->response->body('Not found');
        return;
    }
    # resolve symlinks and upward directory parts.
    $file = Path::Tiny::path($file)->realpath->stringify;

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
                gif => 'image/gif',
                ico => 'image/x-icon',
                css => 'text/css',
                js => 'text/javascript',
                eot => 'application/vnd.ms-fontobject',
                otf => 'application/font-sfnt',
                svg => 'image/svg+xml',
                ttf => 'application/font-sfnt',
                woff => 'application/font-woff',
                woff2 => 'font/woff2',
                torrent => 'application/x-bittorrent',
               };

    my $type;
    # no extension => octect-stream
    if ($file =~ m/\.(\w+)$/) {
        $type = $mime->{$1};
    }
    if (index($file, ROOT) != 0 or !$type) {
        $c->response->status(403);
        log_info {
            "Tried to serve $file, refused, outside " . ROOT
              . " or forbidden extension (.txt is not allowed)"
          };
        $c->response->body("Access denied");
        return;
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

