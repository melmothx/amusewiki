package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# use Unicode::Collate::Locale;
# faster but hard to install
use Unicode::ICU::Collator;

=head2 list_titles($id)

List the title for a single site

=cut

sub title_list {
    my ($self, $id, $locale) = @_;
    $id ||= 'default';
    my @titles = $self->search({
                                site_id => $id,
                                deleted => '',
                               },
                               {
                                order_by => 'title',
                               });
    # we have to do the sorting to avoid the specific of the DB...
    # e.g., sqlite sucks
    my $collator = Unicode::ICU::Collator->new($locale);
    # my $collator = Unicode::Collate::Locale->new(locale => $locale);
    @titles = sort { $collator->cmp($a->list_title, $b->list_title) } @titles;
    return \@titles;
}

1;

