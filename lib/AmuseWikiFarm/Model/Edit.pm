package AmuseWikiFarm::Model::Edit;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Archive::Edit',
);

sub prepare_arguments {
    my ($self, $c) = @_;
    $c->log->debug("Loading backend for editing pages");
    my $args = {
                site_schema => $c->stash->{site},
                basedir => $c->config->{home},
               };
    return $args;
}


=head1 NAME

AmuseWikiFarm::Model::Edit

=head1 SYNOPSIS

Wrap and instantiate AmuseWikiFarm::Archive::Edit

See L<AmuseWikiFarm>

=cut

1;

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
