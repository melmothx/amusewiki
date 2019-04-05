package AmuseWikiFarm::Schema::ResultSet::NodeBody;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub find_by_lang {
    my ($self, $lang) = @_;
    my $me = $self->current_source_alias;
    return $self->find({ "$me.lang" => $lang });
}

sub not_empty {
    return shift->search({ title_muse => { '!=' => '' } });
}

1;
