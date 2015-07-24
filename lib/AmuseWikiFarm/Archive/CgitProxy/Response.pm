package AmuseWikiFarm::Archive::CgitProxy::Response;

use strict;
use warnings;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use Encode qw/decode/;

has success => (is => 'ro', isa => 'Bool');
has url => (is => 'ro', isa => 'Str');
has status => (is => 'ro', isa => 'Str');
has reason => (is => 'ro', isa => 'Str');
has content => (is => 'ro', isa => 'Str');
has headers => (is => 'ro', isa => 'HashRef');

has verbatim => (is => 'ro',
                 lazy => 1,
                 isa => 'Bool',
                 builder => '_build_verbatim',
                );

sub _build_verbatim {
    my $self = shift;
    if ($self->headers->{'content-disposition'}) {
        return 1;
    }
    return 0;
}

sub html {
    my $self = shift;
    if (!$self->verbatim && $self->headers->{'content-type'}) {
        if ($self->content_type eq 'text/html; charset=UTF-8') {
            my $content;
            eval { $content = Encode::decode('UTF-8', $self->content) };
            $content ? return $content : return $self->content;
        }
    }
    return '';
}

sub content_type {
    return shift->headers->{'content-type'};
}

sub last_modified {
    return shift->headers->{'last-modified'};
}

sub disposition  {
    return shift->headers->{'content-disposition'};
}

sub expires {
    return shift->headers->{expires};
}


__PACKAGE__->meta->make_immutable;

1;
