package AmuseWikiFarm::Schema::ResultSet::Category;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Unicode::Collate::Locale;

=head2 listing($site_id, $type, $locale)

List the categories for a site. Return a sorted list with name, bare
uri, title count.

=cut

sub listing {
    my ($self, $id, $type, $locale) = @_;
    $id ||= 'default';
    my @titles = $self->search({
                                site_id => $id,
                                type    => $type,
                               });

    my $collator = Unicode::Collate::Locale->new(locale => $locale);
    my @result = map { { name => $_->name, uri => $_->uri, count => $_->title_count } }
      @titles;

    @titles = sort { $collator->cmp($a->{name}, $b->{name}) } @result;
    return \@titles;
}

1;

