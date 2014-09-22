#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;

print "Migrating site.canonical to new schema. This is safe to repeat.\n";
my ($tld) = @ARGV;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

foreach my $site ($schema->resultset('Site')->all) {
    if (my $canonical = $site->canonical) {
        $canonical =~ s!https?://!!;
        $canonical =~ s!/.*$!!;
        warn "Setting new canonical to " . $canonical;
        $site->canonical($canonical);
    }
    else {
        # canonical can't be null
        my $id = $site->id;
        die "Missing canonical and no domain provided!" unless $tld;
        my $new = $id . '.' . $tld;
        warn "Empty canonical, which can't be null, forcing to $id.$tld";
        $site->canonical($new);
    }
    $site->update;
    foreach my $vhost ($site->vhosts) {
        if ($site->canonical eq $vhost->name) {
            warn "Deleting " . $vhost->name . " from vhost, is the canonical";
            $vhost->delete;
        }
    }
}
