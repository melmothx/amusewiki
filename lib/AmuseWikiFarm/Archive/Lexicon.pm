package AmuseWikiFarm::Archive::Lexicon::Handles;

use utf8;
use strict;
use warnings;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;
sub import_po_file {
    my ($self, $lang, $path, $fallback) = @_;
    Locale::Maketext::Lexicon->import({ $lang => [ Gettext => $path ],
                                        _auto => $fallback,
                                        _decode => 1 });
}

package AmuseWikiFarm::Archive::Lexicon::Site;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Maybe Object/;
use Try::Tiny;
use HTML::Entities qw/encode_entities decode_entities/;

has global => (is => 'ro', isa => Object);
has site => (is => 'ro', isa => Maybe[Object]);

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

package AmuseWikiFarm::Archive::Lexicon;

use Moo;
use Types::Standard qw/Str HashRef Object/;
use Path::Tiny;
use AmuseWikiFarm::Log::Contextual;

has system_wide_po_dir => (is => 'ro', isa => Str, required => 1);
has repo_dir => (is => 'ro', isa => Str, required => 1);
has loaded => (is => 'ro', isa => HashRef[HashRef[Object]], default => sub { +{} });
has globals => (is => 'ro', isa => HashRef[Object], default => sub { +{} });

sub localizer {
    my ($self, $lang, $repo) = @_;
    $repo ||= 'amw';
    $lang ||= 'en';
    if (my $handler = $self->loaded->{$repo}->{$lang}) {
        log_debug { "$lang for $repo has already been loaded" };
        return $handler;
    }
    my $global = $self->globals->{$lang};
    unless ($global) {
        my $po = path($self->system_wide_po_dir, "$lang.po")->stringify;
        if (-f $po) {
            log_debug { "Loading $po file for $lang" };
            AmuseWikiFarm::Archive::Lexicon::Handles->import_po_file($lang, $po, 1);
        }
        else {
            log_error { "$po not found for $lang" };
        }
        $global = AmuseWikiFarm::Archive::Lexicon::Handles->get_handle($lang);
        $self->globals->{$lang} = $global;
    }
    my $site;
    my $local = path($self->repo_dir, $repo, locales => "$lang.po")->stringify;
    if (-f $local) {
        my $internal = "i-amw-$repo-$lang";
        log_debug { "Loading $local po" };
        AmuseWikiFarm::Archive::Lexicon::Handles->import_po_file($internal, $local, 0);
        $site = AmuseWikiFarm::Archive::Lexicon::Handles->get_handle($internal);
    }
    else {
        log_debug { "$local doesn't exist, not loading" };
    }
    my $localizer = AmuseWikiFarm::Archive::Lexicon::Site->new(site => $site,
                                                               global => $global);
    $self->loaded->{$repo}->{$lang} = $localizer;
    return $localizer;
}


1;

