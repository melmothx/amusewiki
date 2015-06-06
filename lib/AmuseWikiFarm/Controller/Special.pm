package AmuseWikiFarm::Controller::Special;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::Text
        AmuseWikiFarm::Role::Controller::ListingDisplay/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/site_robot_index') :PathPart('special') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->log->debug('stashing f_class');
    my $titles = $c->stash->{site}->titles;
    my $rs;
    if ($c->user_exists) {
        $rs = $titles->published_or_deferred_specials;
    }
    else {
        $rs = $titles->published_specials;
    }
    $c->stash(
              f_class => 'special',
              texts_rs => $rs,
              page_title => $c->loc('Special pages'),
             );
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

