package AmuseWikiFarm::Utils::Paths;

use utf8;
use strict;
use warnings;

use Path::Tiny;

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

1;
