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
    $c->stash(breadcrumbs => [
                              {
                               uri => $c->uri_for_action('/aggregation/manage'),
                               label => $c->loc("Aggregations"),
                              }
                             ]);
}

sub manage :Chained('aggregate') :PathPart('manage') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(
              load_datatables => 1,
              aggregations => [ $c->stash->{site}->aggregations->sorted->hri ],
             );
}

sub edit :Chained('aggregate') :PathPart('edit') :Args {
    my ($self, $c, $id) = @_;
    my $site = $c->stash->{site};
    my $params = $c->request->body_params;
    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/attachments/edit'),
       label => $c->loc('Edit'),
      };
    if (delete $params->{update}) {
        Dlog_debug { "Params are $_" } $params;
        my $updated = $site->create_aggregation($params);
        $c->flash(status_msg => $c->loc("Thanks!"));
        return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
    }
    if ($id and $id =~ /\A\d+\z/a) {
        if (my $agg = $site->aggregations->find($id)) {
            $c->stash(aggregation => $agg->serialize);
        }
        else {
            return $c->detach('/not_found');
        }
    }
    else {
        $c->stash(aggregation => {});
    }
}

sub remove :Chained('aggregate') :PathPart('remove') :Args(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ /\A\d+\z/a) {
        if (my $agg = $c->stash->{site}->aggregations->find($id)) {
            $agg->bump_oai_pmh_records;
            $agg->delete;
            $c->flash(status_msg => $c->loc("Record deleted!"));
        }
    }
    return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
}

sub title :Chained('aggregate') :PathPart('title') :Args(1) {
    my ($self, $c, $title_id) = @_;
    my $site = $c->stash->{site};
    my $ok = 0;
    my $int = qr{\A\d+\z}a;
    my $params = $c->request->body_params;
    if ($title_id =~ m/$int/) {
        if (my $title = $site->titles->texts_only->status_is_published->find($title_id)) {
            if ($title->aggregate($params)) {
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
