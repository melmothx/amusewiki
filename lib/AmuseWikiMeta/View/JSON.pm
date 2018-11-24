package AmuseWikiMeta::View::JSON;

use strict;
use warnings;
use base qw/Catalyst::View::JSON/;

__PACKAGE__->config(expose_stash => 'json');

1;
