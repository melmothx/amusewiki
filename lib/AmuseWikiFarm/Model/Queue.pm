package AmuseWikiFarm::Model::Queue;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Archive::Queue',
);

sub prepare_arguments {
    my ($self, $c) = @_;
    $c->log->debug("Loading queue system");
    my $args = {
                dbic => $c->model('DB'),
               };
    return $args;
}


=head1 NAME

AmuseWikiFarm::Model::Queue

=head1 SYNOPSIS

Wrap and instantiate AmuseWikiFarm::Archive::Queue

See L<AmuseWikiFarm>

=cut

1;

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
