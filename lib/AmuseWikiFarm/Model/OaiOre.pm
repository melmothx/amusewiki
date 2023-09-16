package AmuseWikiFarm::Model::OaiOre;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

use AmuseWikiFarm::Log::Contextual;

__PACKAGE__->config(class => 'AmuseWikiFarm::Archive::OAI::ORE');

sub prepare_arguments {
    my ($self, $c) = @_;
    my %args = (
                text => $c->stash->{text},
                uri_maker => sub { $c->uri_for(@_) },
               );
    return \%args;
}


=head1 NAME

AmuseWikiFarm::Model::OaiOre - AOI ORE model

=head1 DESCRIPTION

Wrap L<AmuseWikiFarm::Archive::OAI::ORE> into the catalyst app

=cut

1;
