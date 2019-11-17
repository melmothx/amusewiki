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

    # first, we handled deletions and reschedule
    if (my $delete = $c->request->body_parameters->{delete_job}) {
        if (my $job = $rs->find($delete)) {
            $job->delete;
            $c->flash(status_msg => $c->loc("Job deleted"));
        }
    }
    elsif (my $reschedule = $c->request->body_parameters->{reschedule_job}) {
        if (my $job = $rs->find($reschedule)) {
            if ($job->reschedule) {
                $c->flash(status_msg => $c->loc("Job rescheduled"));
            }
        }
    }
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
