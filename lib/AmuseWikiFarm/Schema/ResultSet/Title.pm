package AmuseWikiFarm::Schema::ResultSet::Title;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Unicode::Collate::Locale;

=head2 list_titles($id)

List the title for a single site

=cut

sub list_titles {
    my ($self, $id, $locale) = @_;
    $id ||= 'default';
    my @titles = $self->search({
                                site_id => $id,
                                deleted => '',
                               });
    # we have to do the sorting to avoid the specific of the DB...
    # e.g., sqlite sucks
    my $collator = Unicode::Collate::Locale->new(locale => $locale);
    @titles = sort { $collator->cmp($a->list_title, $b->list_title) } @titles;
    return \@titles;
}

1;

