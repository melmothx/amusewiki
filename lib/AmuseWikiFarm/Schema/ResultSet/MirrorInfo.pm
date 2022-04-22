package AmuseWikiFarm::Schema::ResultSet::MirrorInfo;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DateTime;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse qw/build_full_uri/;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::MirrorInfo - MirrorInfo resultset

=cut

sub hri {
    my $self = shift;
    return $self->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}

sub download_completed {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.download_destination" => { '!=' => '' } });
}

sub with_exceptions {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.mirror_exception" => { '!=' => '' } });
}

sub without_origin {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.mirror_origin_id" => undef });
}

sub detail_list {
    my $self = shift;
    my @entries = $self->search(undef, { prefetch => [qw/title attachment/] })->hri->all;
    my @good;
    while (@entries) {
        my $entry = shift @entries;
        if (my $title = delete $entry->{title}) {
            $title->{class} = 'Title';
            $entry->{full_uri} = build_full_uri($title);
            push @good, $entry;
        }
        elsif (my $att = delete $entry->{attachment}) {
            if ($att->{f_class} and $att->{f_class} ne 'attachment') {
                $att->{class} = 'Attachment';
                $entry->{full_uri} = build_full_uri($att);
                push @good, $entry;
            }
        }
    }
    return \@good;
}

1;
