package AmuseWikiFarm::View::Email::Template;

use strict;
use base 'Catalyst::View::Email::Template';

__PACKAGE__->config(
    stash_key       => 'email',
    template_prefix => 'email',
    default => {
        view => 'TT',
        charset => 'utf-8',
        content_type => 'text/plain',
    },
);

=head1 NAME

AmuseWikiFarm::View::Email::Template - Templated Email View for AmuseWikiFarm

=head1 DESCRIPTION

View for sending template-generated email from AmuseWikiFarm.

=head1 AUTHOR

Marco,,,

=head1 SEE ALSO

L<AmuseWikiFarm>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
