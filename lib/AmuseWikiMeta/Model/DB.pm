package AmuseWikiMeta::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'AmuseWikiFarm::Schema',
    connect_info => 'amuse',
);

1;
