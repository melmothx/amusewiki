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
    return 
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
