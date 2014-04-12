package AmuseWikiFarm::Schema::ResultSet::Revision;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


=head2 pending

Return a list of pending revisions

=cut

sub pending {
    return shift->search({ status => 'pending' },
                         { order_by => { -desc => 'updated' }});
}


1;
