package AmuseWikiMeta::Model::OPDS;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(class => 'XML::OPDS');

1;
