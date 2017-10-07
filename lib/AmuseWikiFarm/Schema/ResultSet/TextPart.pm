package AmuseWikiFarm::Schema::ResultSet::TextPart;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::TextPart - resultset for text parts

=cut

sub hri {
    my $self = shift;
    return $self->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

sub ordered {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search(undef, { order_by => ["$me.part_order"] });
}

sub toc_entries {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.toc_index" => { '>' => 0 } });
}

1;


