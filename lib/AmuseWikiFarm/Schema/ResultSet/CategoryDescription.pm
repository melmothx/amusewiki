package AmuseWikiFarm::Schema::ResultSet::CategoryDescription;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Text::Amuse::Functions qw/muse_to_object/;
use AmuseWikiFarm::Log::Contextual;

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
