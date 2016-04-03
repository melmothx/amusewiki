package AmuseWikiFarm::Model::Lexicon;

use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';
use AmuseWikiFarm::Log::Contextual;
use Path::Tiny;

__PACKAGE__->config(
    class => 'AmuseWikiFarm::Archive::Lexicon',
);

sub prepare_arguments {
    my ($self, $app) = @_;
    my $path = path('repo')->absolute;
    my %opts = (
                system_wide_po_dir => $app->path_to(qw/lib AmuseWikiFarm I18N/)->stringify,
                repo_dir => $path->stringify,
               );
    Dlog_debug { "Loading lexicon with $_" } \%opts;
    return \%opts;
}

=head1 NAME

AmuseWikiFarm::Model::Lexicon - Lexicon Model

=head1 SYNOPSIS

See L<AmuseWikiFarm>

=head1 DESCRIPTION

Wrap L<AmuseWikiFarm::Archive::Lexicon> into the catalyst app

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
