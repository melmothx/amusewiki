package AmuseWikiFarm::Archive::OAI::PMH;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Object Str HashRef ArrayRef/;

has site => (
             is => 'ro',
             required => 1,
             isa => Object,
            );


1;
