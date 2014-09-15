package AmuseWikiFarm::Model::Cache;

use strict;
use warnings;
use base 'Catalyst::Model::Factory';

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Archive::Cache',
);

1;
