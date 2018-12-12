package AmuseWikiFarm::Model::Cgit;

use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'AmuseWikiFarm::Archive::CgitEmulated' );

1;
