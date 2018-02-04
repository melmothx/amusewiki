package TestApp::Model::DBICSchema;

eval { require Catalyst::Model::DBIC::Schema }; return 1 if $@;
@ISA = qw/Catalyst::Model::DBIC::Schema/;

use strict;
use warnings;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'AmuseWikiFarm::Schema',
    connect_info => 'amuse',
);

1;
