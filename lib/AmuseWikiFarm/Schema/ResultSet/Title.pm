package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# use Unicode::Collate::Locale;
# faster but hard to install
# use Unicode::ICU::Collator;

=head2 list_titles($id)

List the title for a single site

=cut

sub published_texts {
    my $self = shift;
    return $self->search({ deleted => '' }, { order_by => 'title' });
}

1;

