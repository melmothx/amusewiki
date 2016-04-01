package CatalystX::AmuseWiki::I18N;

use Moose::Role;
use namespace::autoclean;

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

CatalystX::AmuseWiki::I18N;

=head1 DESCRIPTION

This is a replacement for Catalyst::Plugin::I18N.

Please note that this plugin doesn't do anything. I came to the
(unbelievable!) conclusion that whenever you use a plugin which isn't
strictly coupled with the web application, you are doing it the wrong
way.

The real job is done by L<AmuseWikiFarm::Archive::Lexicon>.

However, this plugin does something useful after all. Beside providing
a compatibility layer with the existing calls, it keeps the stash
operation encapsulated. The relevant key is C<lh>. If not found, when
calling C<loc> or C<loc_html> you are going to get an exception and,
more important, a context dump in the logs.

=head1 METHODS

=head2 set_language($lang_id, $site_id)

Calls C<localizer> passing the arguments to the Lexicon model.

=head2 loc($key, @args)

Just call:

  $c->stash->{lh}->loc($key, @args)

The result is NOT HTML safe.

=head2 loc_html($key, @args);

  $c->stash->{lh}->loc_html($key, @args)

The result is HTML safe.

=head1 TEMPLATE METHODS

Whenever you see a bare [% loc('string') %] in the template, you are
actually calling C<loc_html> because of the macro installed in
root/src/macros.tt.

If you need an unescaped translation, you can call

 [% lh.loc('string', args) %]

(where args is an arrayref or a list).

=cut

sub loc {
    my $c = shift;
    if (my $lh = $c->stash->{lh}) {
        return $lh->loc(@_);
    }
    else {
        Dlog_error { "Cannot find lh in the stash: $_" } $c;
        die "no lh found: @_";
    }
};

sub loc_html {
    my $c = shift;
    if (my $lh = $c->stash->{lh}) {
        return $lh->loc_html(@_);
    }
    else {
        Dlog_error { "Cannot find lh in the stash: $_" } $c;
        die "no lh found: @_";
    }
};

sub set_language {
    my $c = shift;
    $c->stash(lh => $c->model('Lexicon')->localizer(@_));
}


1;
