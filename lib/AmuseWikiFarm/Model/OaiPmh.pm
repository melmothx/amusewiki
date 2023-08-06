package AmuseWikiFarm::Model::OaiPmh;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

use AmuseWikiFarm::Log::Contextual;

__PACKAGE__->config(class => 'AmuseWikiFarm::Archive::OAI::PMH');

sub prepare_arguments {
    my ($self, $c) = @_;
    my %args = (
                site => $c->stash->{site},
                oai_pmh_url => $c->uri_for_action('/oai/pmh'),
               );
    return \%args;
}

=head1 NAME

AmuseWikiFarm::Model::OaiPmh - Bookbuilder helper model

=head1 DESCRIPTION

Wrap L<AmuseWikiFarm::Archive::OAI::PMH> into the catalyst app

=cut

1;
