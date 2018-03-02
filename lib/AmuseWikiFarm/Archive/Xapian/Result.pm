package AmuseWikiFarm::Archive::Xapian::Result;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/Maybe Object HashRef ArrayRef InstanceOf/;
use JSON::MaybeXS;
use AmuseWikiFarm::Log::Contextual;
use namespace::clean;

has pager => (is => 'ro',
              required => 1,
              isa => InstanceOf['Data::Page']);

has matches => (is => 'ro',
                required => 1,
                isa => ArrayRef[HashRef]);

has facets => (is => 'ro',
               required => 1,
               isa => HashRef[ArrayRef[HashRef]]);

has site => (is => 'ro',
             isa => Maybe[Object]);

has lh => (is => 'ro',
           isa => Maybe[Object]);

has authors => (is => 'lazy');

has topics => (is => 'lazy');

has dates => (is => 'lazy');

has pubdates => (is => 'lazy');

has num_pages => (is => 'lazy');


sub _build_authors {
    my $self = shift;
    my $list = $self->unpack_json_facets($self->facets->{author});
}

sub _build_topics {
    my $self = shift;
    my $list = $self->unpack_json_facets($self->facets->{author});
}

sub _build_dates {
    my $self = shift;
    my $list = $self->facets->{date};
}

sub _build_pubdates {
    my $self = shift;
    my $list = $self->facets->{pubdate};
}

sub _build_num_pages {
    my $self = shift;
    my $list = $self->facets->{pages};
}


=head2 unpack_json_facets [INTERNAL]

This is horrid, but there is no multivalue and subclassing MatchSpy
leads to a beautiful segmentation fault (core dumped)

=cut

sub unpack_json_facets {
    my ($self, $arrayref) = @_;
    if ($arrayref) {
        my @raw = @$arrayref;
        my %out;
        while (@raw) {
            my $record = shift @raw;
            my @values = @{decode_json($record->{value})};
            my $count = $record->{count};
            foreach my $v (@values) {
                $out{$v} += $count;
            }
        }
        return [ map { +{ value => $_, count => $out{$_} } } sort keys %out ];
    }
    return undef;
}



1;
