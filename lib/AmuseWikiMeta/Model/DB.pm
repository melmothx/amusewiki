package AmuseWikiMeta::Model::DB;

use strict;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class => 'AmuseWikiMeta::Archive::Config',
);

1;
