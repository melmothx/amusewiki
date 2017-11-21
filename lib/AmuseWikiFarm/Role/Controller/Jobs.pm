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
    # then continue as nothing happened

    my @columns = $rs->result_source->columns;
    my %order_fields = map { $_ => 1 } @columns;
    Dlog_debug { "Permitted fields: $_ " } \%order_fields;
    unless ($order_by and $order_fields{$order_by}) {
        $order_by = 'completed';
    }
    if ($direction and $direction =~ m/(desc|asc)/) {
        $direction = $1;
    }
    else {
        $direction = 'desc';
    }
    my ($filter_field, $filter_search, $search_query);
    if (my $search_field = $c->req->query_params->{field}) {
        if ($order_fields{$search_field}) {
            my $search_value = $c->req->query_params->{search};
            if (length($search_value)) {
                my @values = grep { length($_) } split(/\s+/, $search_value);
                my %exact = (
                             id => 1,
                             site_id => 1,
                             priority => 1,
                            );
                if ($exact{$search_field}) {
                    $search_query = [ map { +{ $search_field => $_ } } @values ];
                }
                else {
                    $search_query = [ map { +{ $search_field => { -like => '%' . $_ . '%' } } } @values ];
                }
                Dlog_debug { "Searching jobs with values $_" } $search_query;
                $filter_field = $search_field;
                $filter_search = $search_value;
            }
        }
    }
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    my $all = $rs->search($search_query,
                          {
                           order_by => [
                                        { '-' . $direction => $order_by, },
                                        { -desc => 'id' },
                                       ],
                           page => $page,
                           rows => $c->stash->{site}->pagination_size,
                          });
    my $pager = $all->pager;
    # called from a role
    my $action = $c->action;
    my $format_link = sub {
        return $c->uri_for($action, $order_by, $direction, $_[0], {
                                                                                field => $filter_field,
                                                                                search => $filter_search,
                                                                               });
    };
    $c->stash(jobs => [ $all->all ],
              search_fields => \@columns,
              pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
              template => 'admin/jobs.tt',
             );
}

1;
