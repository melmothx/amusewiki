package AmuseWikiFarm::Utils::Paths;

use utf8;
use strict;
use warnings;
use Path::Tiny;
use AmuseWikiFarm::Log::Contextual;

=head2 root_install_directory

Where to find the root/src and mkits

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
    _install_location(qw/mkits/);
}

sub templates_location {
    _install_location(qw/root src/);
}

sub static_file_location {
    _install_location(qw/root static/);
}

1;
