package AmuseWikiFarm::Controller::Stats;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Stats - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub stats :Chained('/site_robot_index') :CaptureArgs(0) {}

sub register :Chained('stats') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->body_params;
    my $ua = $c->stash->{amw_user_agent};
    my $site = $c->stash->{site};
    Dlog_debug { "Params for registering download are $_" } $params;
    my $body = 'Text not found';
    if ($params->{id} && $params->{type}) {
        if ($ua->browser_string && !$ua->robot) {
            log_debug { "User is not a robot: " . $ua->user_agent };
            if ($params->{id} =~ m/\A([1-9][0-9]*)\z/) {
                my $id = $1;
                if (my $text = $site->titles->published_texts->find($id)) {
                    log_debug { "Registering download for " . $text->uri };
                    $text->insert_stat_record($params->{type} . '',
                                              $ua->user_agent);
                    $body = 'OK';
                }
            }
        }
    }
    $c->response->body($body);
}

sub popular :Chained('stats') :Args {
    my ($self, $c, $page) = @_;
    my $results = $c->stash->{site}->popular_titles($page);
    my $pager = $results->pager;
    my $format_link = sub {
        return $c->uri_for_action('/stats/popular', $_[0]);
    };
    my @res;
    while (my $row = $results->next) {
        push @res, $row->title;
    }
    $c->stash(pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
              nav => 'popular',
              page_title => $c->loc('Popular texts'),
              texts => \@res);
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
