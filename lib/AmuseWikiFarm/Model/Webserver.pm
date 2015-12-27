package AmuseWikiFarm::Model::Webserver;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'AmuseWikiFarm::Utils::Webserver' );

1;
