package AmuseWikiFarm::Archive::Lexicon;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str HashRef/;
use Path::Tiny;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::Lexicon::Site;
use AmuseWikiFarm::Archive::Lexicon::Handles;

has system_wide_po_dir => (is => 'ro', isa => Str, required => 1);
has repo_dir => (is => 'ro', isa => Str, required => 1);

=head1 NAME

AmuseWikiFarm::Archive::Lexicon - I18N for AmuseWiki

=head1 SYNOPSIS

 my $i18n = AmuseWikiFarm::Archive::Lexicon->new(system_wide_po_dir => 'lib/AmuseWikiFarm/I18N',
                                                 repo_dir => 'repo');
 my $lh = $i18n->localizer(hr => amw);
 print $lh->loc('Test');
 print $lh->loc_html('Test');

=head1 DESCRIPTION

This model is used to manage the localization handles. The object
should be created passing the path to the global po files, and the
site repos root. When you ask for a localizer, you pass the language
and the repo id, resulting in an
L<AmuseWikiFarm::Archive::Lexicon::Site> object upon which you can
call C<loc> and L<loc_html>.

=head1 CONSTRUCTORS

=head2 system_wide_po_dir

=head2 repo_dir

=head1 METHODS

=head2 localizer($lang, $repo_id)

=head1 AUTHOR

Marco Pessotto

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



has loaded => (is => 'ro', isa => HashRef, default => sub { +{} });
has globals => (is => 'ro', isa => HashRef, default => sub { +{} });

sub localizer {
    my ($self, $lang, $repo) = @_;
    $repo ||= 'amw';
    $lang ||= 'en';
    die "Bad repo name" unless $repo =~ m/\A[a-z0-9]+\z/;
    die "Bad lang name" unless $lang =~ m/\A[a-z0-9]+\z/;
    if (my $handler = $self->loaded->{$repo}->{$lang}) {
        Dlog_debug { "$lang for $repo has already been loaded: $_" } $handler;;
        if ($handler->is_obsolete) {
            log_debug { "However, $lang for $repo is obsolete" };
        }
        else {
            log_debug { "Handle is not obsolete" };
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
            log_error { "$po not found for $repo $lang" };
        }
        $global = AmuseWikiFarm::Archive::Lexicon::Handles->get_handle($lang);
        $self->globals->{$lang} = $global;
    }
    my $site;
    my $local = path($self->repo_dir, $repo, site_files => locales => "$lang.po");
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

