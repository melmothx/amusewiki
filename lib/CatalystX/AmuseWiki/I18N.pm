package CatalystX::AmuseWiki::I18N;

use Moose::Role;
use namespace::autoclean;

use HTML::Entities qw/encode_entities decode_entities/;
use AmuseWikiFarm::Log::Contextual;

sub loc {
    my ($c, $key, @args) = @_;
    return '' unless defined $key;
    if (@args == 1 and $args[0] and (ref($args[0]) eq 'ARRAY')) {
        my $arrayref = shift @args;
        @args = @$arrayref;
    }
    # we never serve c.loc directly, so we unescape the string first
    $key = decode_entities($key);
    if (my $lh = $c->stash->{lh}) {
        return $lh->loc($key, @args);
    }
    else {
        Dlog_error { "Cannot find lh in the stash: $_" } $c;
        return $key;
    }
};

sub set_language {
    my ($c, @args) = @_;
    $c->stash(lh => $c->model('Lexicon')->localizer(@args));
}


1;
