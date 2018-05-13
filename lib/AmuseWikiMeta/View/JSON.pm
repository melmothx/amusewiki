package AmuseWikiMeta::View::JSON;

use base qw/Catalyst::View::JSON/;

__PACKAGE__->config(expose_stash => 'json');

1;
