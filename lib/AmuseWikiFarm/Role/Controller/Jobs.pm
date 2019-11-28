package AmuseWikiFarm::Role::Controller::Jobs;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;

requires qw/get_jobs/;

use AmuseWikiFarm::Utils::Paginator;
use AmuseWikiFarm::Log::Contextual;

sub jobs :Chained('get_jobs') :PathPart('show') :Args {
    my ($self, $c, $order_by, $direction, $page) = @_;
    my $rs = delete $c->stash->{all_jobs};

    my @flash;
    # first, we handled deletions and reschedule
    if (my $delete = $c->request->body_parameters->{delete_job}) {
        Dlog_info { "Deleting jobs $_" } $delete;
        my $jobs = $rs->search(
                               { id => [ grep { $_ } @{ ref($delete) ? $delete : [ $delete ] } ] }
                              );
        my $total = 0;
        foreach my $j ($jobs->all) {
            # same as ->delete_all
            $total++;
            $j->delete;
        }
        push @flash, $c->loc("[_1] jobs deleted", [$total]);
    }
    if (my $reschedule = $c->request->body_parameters->{reschedule_job}) {
        Dlog_info { "Rescheduling jobs $_" } $reschedule;
        my $jobs = $rs->search(
                               { id => [ grep { $_ } @{ ref($reschedule) ? $reschedule : [ $reschedule ] } ] }
                              );
        my $total = 0;
        foreach my $j ($jobs->all) {
            $total++;
            $j->reschedule;
        }
        push @flash, $c->loc("[_1] jobs rescheduled", [$total]);
    }
    $c->flash(status_msg => join(' / ', @flash)) if @flash;
    $c->stash(template => 'admin/jobs.tt',
              load_datatables => 1);
}

sub source_ajax :Chained('get_jobs') :PathPart('source-ajax') :Args(0) {
    my ($self, $c) = @_;
    my $rs = delete $c->stash->{all_jobs};
    my @data = $rs->search(undef,
                           {
                            '+select' => ['site.canonical'],
                            '+as' => ['canonical'],
                            join => [qw/site/],
                            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                           })->all;
    $c->stash(json => { data => \@data });
    $c->detach($c->view('JSON'));
}


1;
