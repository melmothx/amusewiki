package AmuseWikiFarm::Controller::Archive;

use Moose;
with qw/AmuseWikiFarm::Role::Controller::RegularListing
        AmuseWikiFarm::Role::Controller::ListingDisplay
       /;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub pre_base :Chained('/site_robot_index') :PathPart('archive') :CaptureArgs(0) {}

sub archive_by_lang :Chained('base') :PathPart('') :Args(1) {
    my ($self, $c, $lang) = @_;
    my $rs = delete $c->stash->{texts_rs};
    $c->log->debug("In $lang");
    if (my $label = $c->stash->{site}->known_langs->{$lang}) {
        my $resultset = $rs->search({ lang => $lang });
        my $cache = $c->model('Cache',
                              site_id => $c->stash->{site}->id,
                              type => 'library',
                              subtype => $c->stash->{f_class},
                              # here we use the language of the filtering
                              by_lang => 1,
                              lang => $lang,
                              resultset => $resultset,
                             );
        $c->stash(texts => $cache->texts,
                  pager => $cache->pager,
                  text_count => $cache->text_count,
                  show_pager => $c->stash->{site}->pagination_needed($cache->text_count),
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

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

