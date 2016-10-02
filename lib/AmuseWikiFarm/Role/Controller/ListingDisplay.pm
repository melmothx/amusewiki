package AmuseWikiFarm::Role::Controller::ListingDisplay;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;

requires qw/base/;

use AmuseWikiFarm::Log::Contextual;

sub listing :Chained('base') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In listing" };
    my $results = $c->stash->{texts_rs}->listing_tokens($c->stash->{current_locale_code});
    Dlog_debug { "Listing: $_" } $results;
    $c->stash(%$results,
              show_pager => $c->stash->{site}->pagination_needed($results->{text_count}),
              template => 'library.tt');
}

1;
