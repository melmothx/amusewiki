package AmuseWikiFarm::Utils::Paths;

use utf8;
use strict;
use warnings;
use Path::Tiny;
use AmuseWikiFarm::Log::Contextual;
use constant ROOT => Path::Tiny->cwd;

=head1 NAME

AmuseWikiFarm::Utils::Paths - common file locations

=head1 FUNCTIONS

All the methods return L<Path::Tiny> objects with realpath directories

=head2 root_install_directory

The direct where the application runs.

=cut

sub root_install_directory {
    my $selfpath = path(__FILE__);
    my $root = $selfpath
      ->parent # Utils
      ->parent; # AmuseWikiFarm;
    if ($root->child('root')->exists) {
        return $root->realpath;
    }
    else {
        # go up another two dir, so we have "lib" and the root.
        $root = $root->parent->parent;
        if ($root->child('root')->exists) {
            return $root->realpath;
        }
    }
    die "Couldn't find the application root for static files. This looks like a bug";
}


=head2 amusewiki_modules_directory

Return the location of lib/AmuseWikiFarm

=head2 mkits_location

mkits directory

=head2 templates_location

root/src directory

=head2 static_file_location

root/static directory

=head2 dbicdh_location

dbicdh directory

=cut



sub amusewiki_modules_directory {
    path(__FILE__)->parent->parent;
}

sub _install_location {
    my (@names) = @_;
    my $path = root_install_directory->child(@names);
    log_debug { "Checking $path" };
    if ($path->exists) {
        return $path;
    }
    else {
        die "Couldn't find the @names location in $path";
    }
}

sub mkits_location {
    return _install_location(qw/mkits/);
}

sub dbicdh_location {
    return _install_location(qw/dbicdh/);
}

sub templates_location {
    return _install_location(qw/root src/);
}

sub static_file_location {
    return _install_location(qw/root static/);
}


sub served_mime_types {
    return  +{
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
}

1;
