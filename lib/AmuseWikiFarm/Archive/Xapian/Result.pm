package AmuseWikiFarm::Archive::Xapian::Result;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Object HashRef ArrayRef InstanceOf/;

has pager => (is => 'ro',
              required => 1,
              isa => InstanceOf['Data::Page']);

has matches => (is => 'ro',
                required => 1,
                isa => ArrayRef[HashRef]);

has facets => (is => 'ro',
               required => 1,
               isa => HashRef);

1;
