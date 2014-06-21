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

=head2 not_published

Return a list of revisions not yet published

=cut

sub not_published {
    return shift->search({ status => { '!=' => 'published'  } },
                         { order_by => { -desc => 'updated' } });
}


1;
