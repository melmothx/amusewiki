#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use AmuseWikiFarm;
use Data::Dumper::Concise;
use Cache::FastMmap;
use File::Copy;

my $config = AmuseWikiFarm->_session_plugin_config;
die Dumper($config) unless $config->{cache_size} && $config->{storage};
copy($config->{storage}, $config->{storage} . '~' . time())
  or die "$config->{storage}: Couldn't make a backup $!";

if (-f $config->{storage}) {
    my $c = Cache::FastMmap->new(raw_values => 0,
                                 unlink_on_exit => 0,
                                 init_file => 0,
                                 cache_size => $config->{cache_size},
                                 share_file => $config->{storage},
                                );
    print Dumper([sort $c->get_keys(2)]);
}
else {
    print "$config->{storage} file doesn't exist, nothing to do\n";
}
