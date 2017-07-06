package AmuseWikiFarm::Schema::ResultSet::TextInternalLink;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::TextInternalLink - resultset for internal links

=head1 METHODS

=head by_uri_and_class

=cut

sub by_uri_and_class {
    my ($self, $uri, $class) = @_;
    die "Wrong usage needs uri and class: <$uri> <$class>" unless $uri && $class;
    my $me = $self->current_source_alias;
    return $self->search({
                          "$me.uri" => $uri,
                          "$me.f_class" => $class,
                         });
}

1;
