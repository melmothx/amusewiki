package AmuseWikiFarm::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    ENCODING => 'utf8',
    render_die => 1,
);

=head1 NAME

AmuseWikiFarm::View::HTML - TT View for AmuseWikiFarm

=head1 DESCRIPTION

TT View for AmuseWikiFarm.

=head1 SEE ALSO

L<AmuseWikiFarm>

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
