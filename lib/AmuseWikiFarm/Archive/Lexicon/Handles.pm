package AmuseWikiFarm::Archive::Lexicon::Handles;

=head1 NAME

AmuseWikiFarm::Archive::Lexicon::Handles - Base class for Maketext

=head1 METHODS

=head2 import_po_file($lang, $path, $fallback)

Calls L<Locale::Maketext::Lexicon> C<import> reading the po file
passed as the second argument for the language in the second argument.

The last argument is a boolean, and it set the C<auto> option. With a
false value, an exception is thrown when the po fil is missing the
translation.

=cut

use utf8;
use strict;
use warnings;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;
sub import_po_file {
    my ($self, $lang, $path, $fallback) = @_;
    die "Missing language" unless $lang;
    die "Bad lang name $lang" unless $lang =~ m/\A[0-9A-Za-z_]+\z/;
    die "$path is not a file" unless -f $path;
    Locale::Maketext::Lexicon->import({ $lang => [ Gettext => $path ],
                                        _auto => $fallback,
                                        _decode => 1 });
}

1;

