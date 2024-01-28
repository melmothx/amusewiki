package AmuseWikiFarm::Schema::ResultSet::Bookcover;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut::HRI');

sub create_and_initalize {
    my ($self, $values) = @_;
    my $bc = $self->create($values);
    $bc->create_working_dir;
    $bc->populate_tokens;
    return $bc;
}

1;
