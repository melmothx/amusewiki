package AmuseWikiFarm::Schema::ResultSet::CategoryDescription;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Text::Amuse::Functions qw/muse_to_object/;

sub update_description {
    my ($self, $lang, $muse) = @_;
    my $html = muse_to_object($muse)->as_html;
    $self->update_or_create({
                             lang => $lang,
                             muse_body => $muse,
                             html_body => $html,
                            });
}



1;
