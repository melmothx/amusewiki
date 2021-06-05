package AmuseWikiFarm::View::StaticFile;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Plack::Util;
use AmuseWikiFarm::Log::Contextual;
use Path::Tiny ();
use AmuseWikiFarm::Utils::Paths;
use Cwd;
use constant ROOT => getcwd();

sub _allowed_symlink {
    my ($self, $c, $file) = @_;
    if (my $site = $c->stash->{site}) {
        if (Path::Tiny::path($site->repo_root)->realpath->subsumes(Path::Tiny::path($file)->realpath)) {
            log_debug { "Serving $file, internal symlink" };
            return 1;
        }
        else {
            log_error { "$file is outside the site tree! Not serving" };
        }
    }
    return 0;
}

sub process {
    my ($self, $c) = @_;
    my $file = $c->stash->{serve_static_file};
    log_debug { "Serving $file" };
    if (-l $file and !$self->_allowed_symlink($c, $file)) {
        $c->response->status(404);
        $c->response->body('Not found');
        return;
    }
    unless ($file and -f $file) {
        log_error { "$file is not a file!" };
        $c->response->status(404);
        $c->response->body('Not found');
        return;
    }
    # resolve symlinks and upward directory parts.
    $file = Path::Tiny::path($file)->realpath->stringify;
    my $mime = AmuseWikiFarm::Utils::Paths::served_mime_types();
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

