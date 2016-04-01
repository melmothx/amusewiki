package AmuseWikiFarm::Archive::Lexicon::Site;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Maybe Object Int Str InstanceOf/;
use Try::Tiny;
use Path::Tiny;
use HTML::Entities qw/encode_entities decode_entities/;

=head1 NAME

AmuseWikiFarm::Archive::Lexicon::Site - localization class

=head2 DESCRIPTION

Objects of this class are constructed by
L<AmuseWikiFarm::Archive::Lexicon> and shouldn't be created manually.

=head1 METHODS

=head1 is_obsolete

Check if the lexicon held in memory is obsolete or not.

=head2 loc($string, @args)

Translate the string interpolating @args.

Internally, this object usually holds two handles. One is the global
one, one is the local one (which takes precedence).

=head2 loc_html($string, @args)

Same as C<loc>, but the result escapes the HTML entities, including
the single quote.

Equivalent to:

  encode_entities($self->loc($string, @args), q{<>&"'});

=cut


has global => (is => 'ro', isa => Object, required => 1);
has site => (is => 'ro', isa => Maybe[Object], required => 1);
has local_file => (is => 'ro', isa => InstanceOf[qw/Path::Tiny/], required => 1);
has local_file_timestamp => (is => 'ro', isa => Int, default => 0);

sub is_obsolete {
    my $self = shift;
    my $po = $self->local_file;
    if (-f $po and $po->stat->mtime > $self->local_file_timestamp) {
        return 1;
    }
    return 0;
}

sub loc {
    my ($self, $key, @args) = @_;
    return '' unless defined($key) && length($key);
    if (@args == 1) {
        if (defined $args[0]) {
            if (ref($args[0]) eq 'ARRAY') {
                my $arrayref = shift @args;
                @args = @$arrayref;
            }
        }
        else {
            @args = ();
        }
    }
    # in case html is passed:
    $key = decode_entities($key);
    my $out;
    if (my $site = $self->site) {
        try { $out = $site->maketext($key, @args) } catch { $out = undef };
    }
    unless (defined $out) {
        $out = $self->global->maketext($key, @args);
    }
    return $out;
}

sub loc_html {
    my $self = shift;
    return encode_entities($self->loc(@_), q{<>&"'});
}

1;
