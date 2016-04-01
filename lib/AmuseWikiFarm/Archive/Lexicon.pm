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
use Types::Standard qw/Maybe Object Int Str InstanceOf/;
use Try::Tiny;
use Path::Tiny;
use HTML::Entities qw/encode_entities decode_entities/;

has global => (is => 'ro', isa => Object);
has site => (is => 'ro', isa => Maybe[Object]);
has local_file => (is => 'ro', isa => InstanceOf[qw/Path::Tiny/], required => 1);
has local_file_timestamp => (is => 'ro', isa => Int, default => 0);

sub is_obsolete {
    my $self = shift;
    if (my $po = $self->local_file) {
        if (-f $po and $po->stat->mtime > $self->local_file_timestamp) {
            return 1;
        }
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

package AmuseWikiFarm::Archive::Lexicon;

use Moo;
use Types::Standard qw/Str HashRef Object Int/;
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
    die "Bad repo name" unless $repo =~ m/\A[a-z0-9]+\z/;
    die "Bad lang name" unless $lang =~ m/\A[a-z0-9]+\z/;
    if (my $handler = $self->loaded->{$repo}->{$lang}) {
        log_debug { "$lang for $repo has already been loaded" };
        if ($handler->is_obsolete) {
            log_debug { "However, $lang for $repo is obsolete" };
        }
        else {
            return $handler;
        }
    }
    my $global = $self->globals->{$lang};
    unless ($global) {
        my $po = path($self->system_wide_po_dir, "$lang.po")->stringify;
        if (-f $po) {
            log_debug { "Loading $po file for $lang" };
            # these are actual languages
            AmuseWikiFarm::Archive::Lexicon::Handles->import_po_file($lang, $po, 1);
        }
        else {
            log_error { "$po not found for $lang" };
        }
        $global = AmuseWikiFarm::Archive::Lexicon::Handles->get_handle($lang);
        $self->globals->{$lang} = $global;
    }
    my $site;
    my $local = path($self->repo_dir, $repo, locales => "$lang.po");
    my $local_ts = 0;
    if (-f $local) {
        my $internal = "i_amw_${repo}_${lang}";
        log_debug { "Loading $local with name $internal" };
        # not actually documented in the pod, but in the source it is.
        local $Locale::Maketext::USING_LANGUAGE_TAGS = 0;
        AmuseWikiFarm::Archive::Lexicon::Handles->import_po_file($internal, "$local", 0);
        $site = AmuseWikiFarm::Archive::Lexicon::Handles->get_handle($internal)
          or die "$internal couldn't be loaded even if we imported it!";
        Dlog_debug{ $_ } $site;
        $local_ts = $local->stat->mtime;
    }
    else {
        log_debug { "$local doesn't exist, not loading" };
    }
    my $localizer = AmuseWikiFarm::Archive::Lexicon::Site->new(site => $site,
                                                               global => $global,
                                                               local_file_timestamp => $local_ts,
                                                               local_file => $local,
                                                              );
    $self->loaded->{$repo}->{$lang} = $localizer;
    return $localizer;
}


1;

