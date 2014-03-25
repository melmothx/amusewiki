package AmuseWikiFarm::Model::Special;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Archive::Special',
);

sub prepare_arguments {
    my ($self, $c) = @_;
    $c->log->debug("Loading special pages");
    my $args = {
                site_schema => $c->stash->{site},
               };
    return $args;
}


=head1 NAME

AmuseWikiFarm::Model::Special

=head1 SYNOPSIS

Wrap and instantiate AmuseWikiFarm::Archive::Special

See L<AmuseWikiFarm>

=cut

1;

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
