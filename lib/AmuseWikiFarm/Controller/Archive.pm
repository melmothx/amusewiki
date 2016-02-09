package AmuseWikiFarm::Controller::Archive;

use Moose;
with qw/AmuseWikiFarm::Role::Controller::RegularListing
        AmuseWikiFarm::Role::Controller::ListingDisplay
       /;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

sub pre_base :Chained('/site_robot_index') :PathPart('archive') :CaptureArgs(0) {}

sub archive_by_lang :Chained('base') :PathPart('') :Args(1) {
    my ($self, $c, $lang) = @_;
    my $rs = delete $c->stash->{texts_rs};
    log_debug { "In $lang" };
    if (my $label = $c->stash->{site}->known_langs->{$lang}) {
        my $results = $rs->search({ lang => $lang })->listing_tokens($lang);
        Dlog_debug { "Listing tokens are $_" } $results;
        $c->stash(%$results,
                  show_pager => $c->stash->{site}->pagination_needed($results->{text_count}),
                  multilang => {
                                filter_lang => $lang,
                                filter_label => $label,
                               },
                  template => 'library.tt');
        return;
    }
    $c->detach('/not_found');
}

=encoding utf8

=head1 NAME

AmuseWikiFarm::Controller::Archive - amusewiki archive routes

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

