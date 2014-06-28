package AmuseWikiFarm::Model::Feed;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';
use XML::FeedPP;

__PACKAGE__->config(
    class => 'XML::FeedPP::RSS',
);

sub mangle_arguments {
    my ($self, $args) = @_;
    return;
}

=head1 NAME

AmuseWikiFarm::Model::Feed - Feed Model

=head1 SYNOPSIS

See L<AmuseWikiFarm>

=head1 DESCRIPTION

Wrap L<XML::FeedPP> into the catalyst app

=head1 AUTHOR

Marco

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
