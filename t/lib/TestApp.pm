package TestApp;

use 5.010001;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90075;

use strict;
use warnings;
use Catalyst qw/Session
                Session::State::Cookie
                +CatalystX::Session::Store::AMW/;

extends 'Catalyst';

__PACKAGE__->config(name => 'TestApp');

__PACKAGE__->setup();

1;
