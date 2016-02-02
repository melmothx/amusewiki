package AmuseWikiFarm::Schema::ResultSet::CategoryDescription;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Text::Amuse::Functions qw/muse_to_object/;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::CategoryDescription - description resultset

=head1 METHODS

=head2 update_description($language, $muse_body, $modified_by)

Run an C<update_or_create> against the descriptions. Please note that
the category_id is not set by this method, so it's meant to be called on

 $category->category_descriptions->update_description($lang, $body, $author)

This way the C<category_id> is set and everything works, because the
unique constraint is composed by C<lang> and C<category_id>.

=cut

sub update_description {
    my ($self, $lang, $muse, $author) = @_;
    my $html = muse_to_object($muse)->as_html;
    my %update = (
                  lang => $lang,
                  muse_body => $muse,
                  html_body => $html,
                  last_modified_by => $author,
                 );
    Dlog_debug { "update params are $_ " } \%update;
    $self->update_or_create(\%update);
}



1;
