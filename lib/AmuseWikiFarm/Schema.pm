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

=head1 NAME

AmuseWikiFarm::Schema - Database schema for amusewiki

=head1 DESCRIPTION

Load the namespace and use L<DBIx::Class::Schema::Config>. The
application hardcodes C<amuse> as database name, so you basically
always do:

 my $schema = AmuseWikiFarm::Schema->connect('amuse')

and provide a dbic.yaml file with something like this:

 amuse:
   dsn: 'dbi:SQLite:test.db'
   user: ''
   password: ''
   on_connect_do: 'PRAGMA foreign_keys = ON'
   AutoCommit: 1
   RaiseError: 1
   sqlite_unicode: 1
   quote_names: 1

=cut

our $VERSION = 42;

__PACKAGE__->load_components('Schema::Config');
__PACKAGE__->load_components('Helper::Schema::QuoteNames');

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
