package AmuseWikiFarm::Schema::ResultSet::Category;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# use Unicode::Collate::Locale;
use Unicode::ICU::Collator;

=head2 listing($site_id, $type, $locale)

List the categories for a site. Return a sorted list with name, bare
uri, title count.

=cut

sub listing {
    my ($self, $id, $type, $locale) = @_;
    my @cats = $self->search({
                              site_id => $id,
                              type    => $type,
                             },
                             {
                              order_by => 'name',
                             }
                            );
    return $self->_sort_titles($locale, \@cats, "name");
}

sub list_titles {
    my ($self, $id, $locale) = @_;
    my @titles = $self->find($id)->published_titles;
    return $self->_sort_titles($locale, \@titles, "title");
}

sub _sort_titles {
    my ($self, $locale, $list, $method) = @_;
    my $collator = Unicode::ICU::Collator->new($locale);
    my @titles = sort { $collator->cmp($a->$method, $b->$method) } @$list;
    return \@titles;
}

1;

