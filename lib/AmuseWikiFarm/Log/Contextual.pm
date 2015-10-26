package AmuseWikiFarm::Log::Contextual;

use strict;
use warnings;
use base 'Log::Contextual';
 
use Log::Log4perl ':easy';
Log::Log4perl->easy_init($DEBUG);
 
sub arg_default_logger { $_[1] || Log::Log4perl->get_logger }
sub default_import { qw(:dlog :log ) }

1;
