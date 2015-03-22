package CatalystX::AmuseWiki::I18N;

use Moose::Role;
use namespace::autoclean;

use HTML::Entities qw/encode_entities decode_entities/;

around loc => sub {
    my ($orig, $c, $key, @args) = @_;
    # we never call c.loc directly, so we unescape the string first
    $key = decode_entities($key);

    if (my $site = $c->stash->{site}) {
        if (my $lang = $c->stash->{current_locale_code}) {
            my $translated = $site->lexicon_translate($lang, $key, @args);
            if (defined($translated)) {
                return $translated;
            }
        }
    }
    return $c->$orig($key, @args);
};

1;
