package AmuseWikiFarm::Model::Mailer;

use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Utils::Mailer',
);

