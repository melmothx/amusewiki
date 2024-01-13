package AmuseWikiFarm::Controller::Aggregation;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Annotate - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use AmuseWikiFarm::Log::Contextual;

sub aggregate :Chained('/site_user_required') :PathPart('aggregate') :CaptureArgs(0) {
    my ($self, $c) = @_;
    Dlog_debug { "Params are $_" } $c->request->body_params;
}

sub manage :Chained('aggregate') :PathPart('manage') :Args(0) {
    my ($self, $c) = @_;
}

sub title :Chained('aggregate') :PathPart('title') :Args(1) {
    my ($self, $c, $title_id) = @_;
    my $site = $c->stash->{site};
    my $ok = 0;
    my $int = qr{\A\d+\z}a;
    if ($title_id =~ m/$int/) {
        if (my $title = $site->titles->texts_only->status_is_published->find($title_id)) {
            my $title_uri = $title->uri;
            my $removals = $c->request->body_params->{remove_aggregation};
            # this can be an array or an scalar, and that's fine
            # will crash if not a number
            if (my @remove_ids = grep { /$int/ } (ref($removals) ? @$removals : ($removals))) {
                $site->aggregations->search({ 'me.aggregation_id' => \@remove_ids })
                  ->search_related('aggregation_titles')->search({
                                                                  title_uri => $title_uri,
                                                                 })->delete;
                $ok++;
            }
            if (my $add_id = $c->request->body_params->{add_aggregation_id}) {
                if ($add_id =~ m/$int/) {
                    if (my $agg = $site->aggregations->find($add_id)) {
                        unless ($agg->aggregation_titles->find({ title_uri => $title_uri })) {
                            $agg->aggregation_titles->create({ title_uri => $title_uri });
                            $ok++;
                        }
                    }
                }
            }
            if ($ok) {
                $c->flash(status_msg => $c->loc("Thanks!"));
            }
            return $c->response->redirect($c->uri_for($title->full_uri));
        }
    }
    $c->detach('/not_found');
}

sub aggregation :Chained('/site') :PathPart('aggregation') :Args(1) {
    my ($self, $c, $uri) = @_;
    if (my $agg = $c->stash->{site}->aggregations->find({ aggregation_uri => $uri })) {
        $c->stash(
                  aggregation => $agg,
                  texts => AmuseWikiFarm::Utils::Iterator->new([ $agg->titles ])
                 );
    }
    else {
        $c->detach('/not_found');
    }
}

sub series :Chained('/site') :PathPart('aggregation-series') :Args(1) {
    my ($self, $c, $code) = @_;
    my $rs = $c->stash->{site}->aggregations->search({ aggregation_code => $code });
    my %names;
    if ($rs->count) {
        my @all = $rs->sorted->all;
        foreach my $agg (@all) {
            $names{$agg->aggregation_name}++;
        }
        $c->stash(
                  aggregations => \@all,
                  title => join(' / ', sort keys %names),
                 );
    }
    else {
        $c->detach('/not_found');
    }
}

__PACKAGE__->meta->make_immutable;

1;
