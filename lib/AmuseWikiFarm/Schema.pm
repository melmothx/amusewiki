use utf8;
package AmuseWikiFarm::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-01-18 18:28:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:leb09wxTyDnkkszlT5Je0A

our $VERSION = '0.10';

__PACKAGE__->load_components('Schema::Config');

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
