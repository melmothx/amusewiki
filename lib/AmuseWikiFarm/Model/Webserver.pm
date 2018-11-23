package AmuseWikiFarm::Model::Webserver;

use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'AmuseWikiFarm::Utils::Webserver' );

1;
