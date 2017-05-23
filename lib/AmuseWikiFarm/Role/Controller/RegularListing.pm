package AmuseWikiFarm::Role::Controller::RegularListing;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;

requires qw/pre_base/;

use AmuseWikiFarm::Log::Contextual;

sub base :Chained('pre_base') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    log_debug { 'in regular listing base' };
    # if the user is logged in, give him access to deferred as well
    my $titles = $c->stash->{site}->titles->sorted_by_title;
    my $rs = $titles->texts_only;
    if ($c->user_exists) {
        $rs = $rs->status_is_published_or_deferred;
    }
    elsif ($c->stash->{site}->show_preview_when_deferred) {
        log_warn { "Asking for deferred with teaser" };
        $rs = $rs->status_is_published_or_deferred_with_teaser;
    }
    else {
        $rs = $rs->status_is_published;
    }
    $c->stash(
              f_class => 'text',
              texts_rs => $rs,
              page_title => $c->loc('Full list of texts'),
              nav => 'titles',
             );
}

1;
