package AmuseWikiFarm::Xapian;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');

has site => (is => 'ro',
             required => 1,
             isa => 'Str');


__PACKAGE__->meta->make_immutable;

1;
