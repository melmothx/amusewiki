package AmuseWikiFarm::Model::OPDS;

use strict;
use warnings;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class => 'XML::OPDS',
);

=head1 NAME

AmuseWikiFarm::Model::OPDS - OPDS Model

=head1 SYNOPSIS

See L<AmuseWikiFarm>

=head1 DESCRIPTION

Wrap L<XML::OPDS> into the catalyst app

=head1 AUTHOR

Marco Pessotto

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
