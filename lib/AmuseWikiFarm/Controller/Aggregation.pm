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
use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;
use HTML::Entities qw/encode_entities/;

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
    my $site = $c->stash->{site};
    $c->stash(
              load_datatables => 1,
              aggregations => [ map { $_->final_data } $site->aggregations->sorted ],
              series => [ $site->aggregation_series->sorted->hri ],
              page_title => $c->loc("Manage aggregations")
             );
}

sub edit_gate :Chained('aggregate') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->stash->{site}->has_autoimport_file('aggregations')) {
        $c->flash(error_msg => $c->loc('Aggregation editing is disabled (autoimport file present)'));
        $c->response->redirect($c->uri_for_action('/aggregation/manage'));
        log_info { "Aggregation editing is disabled because of autoimport file" };
        $c->detach;
    }
}

sub edit_series :Chained('edit_gate') :PathPart('series') :Args {
    my ($self, $c, $id) = @_;
    my $site = $c->stash->{site};
    my $params = $c->request->body_params;
    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/aggregation/edit_series'),
       label => $c->loc('Edit Series'),
      };
    if (delete $params->{update}) {
        Dlog_debug { "Params are $_" } $params;
        my %clean;
        foreach my $f (qw/aggregation_series_uri
                          aggregation_series_name
                          publisher
                          publication_place
                         /) {
            if ($f eq 'aggregation_series_uri') {
                $clean{$f} = muse_naming_algo($params->{$f});
            }
            else {
                $clean{$f} = $params->{$f};
            }
        }
        if ($clean{aggregation_series_uri} and $clean{aggregation_series_name}) {
            my $series = $site->aggregation_series->find(\%clean,
                                                         { key => 'aggregation_series_uri_site_id_unique' });
            if ($series) {
                if ($params->{is_update}) {
                    $series->update(\%clean);
                    if ($params->{aggregations}) {
                        my @aids = ref($params->{aggregations}) ? @{$params->{aggregations}} : ( $params->{aggregations} );
                        my $order = 0;
                        foreach my $aid (@aids) {
                            if (my $agg = $series->aggregations->find($aid)) {
                                $agg->update({ sorting_pos => ++$order });
                                log_debug { "Updated order for $aid: $order" };
                            }
                            else {
                                log_error { "Aggregation $aid not found is series $id" };
                            }
                        }
                    }
                    $series->bump_oai_pmh_records;
                    $c->flash(status_msg => $c->loc("Thanks!"));
                }
                else {
                    $c->flash(error_msg => $c->loc("Such URI already exists"));
                }
            }
            else {
                $series = $site->aggregation_series->create(\%clean);
                $c->flash(status_msg => $c->loc("Thanks!"));
            }
            if ($series) {
                my $redirect;
                if ($params->{and_create_aggregation}) {
                    $redirect = $c->uri_for_action('/aggregation/edit', [], { series => $series->aggregation_series_uri });
                }
                else {
                    $redirect = $c->uri_for_action('/aggregation/series',
                                                   $series->aggregation_series_uri);
                }
                return $c->response->redirect($redirect);
            }
        }
        else {
            $c->flash(error_msg => $c->loc("Invalid data!"));
        }
        return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
    }
    if ($id and $id =~ /\A\d+\z/a) {
        if (my $series = $site->aggregation_series->find($id)) {
            my $series_data = { $series->get_columns };
            $c->stash(series => $series_data,
                      aggregations => [ $series->aggregations->sorted ]
                     );
        }
        else {
            return $c->detach('/not_found');
        }
    }
    else {
        $c->stash(series => {});
    }
}

sub remove_series :Chained('edit_gate') :PathPart('remove-series') :Args(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ /\A\d+\z/a) {
        if (my $series = $c->stash->{site}->aggregation_series->find($id)) {
            if ($c->check_any_user_role(qw/admin root/)) {
                $series->bump_oai_pmh_records;
                $series->delete;
                $c->flash(status_msg => $c->loc("Record deleted!"));
            }
            else {
                $c->flash(error_msg => $c->loc("Sorry, you can't remove this, please ask an admin"));
            }
        }
    }
    return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
}


sub edit :Chained('edit_gate') :PathPart('edit') :Args {
    my ($self, $c, $id) = @_;
    my $site = $c->stash->{site};
    my $params = $c->request->body_params;
    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/aggregation/edit'),
       label => $c->loc('Edit Aggregation'),
      };
    if (delete $params->{update}) {
        Dlog_debug { "Params are $_" } $params;
        unless (delete $params->{is_update}) {
            # new: check if exists
            if ($site->aggregations->find({ aggregation_uri => muse_naming_algo($params->{aggregation_uri}) })) {
                $c->flash(error_msg => $c->loc("Such URI already exists"));
                return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
            }
        }
        if ($params->{titles} and !ref($params->{titles})) {
            $params->{titles} = [ $params->{titles} ];
        }
        if (my $agg = $site->create_aggregation($params)) {
            # handle the annotations
            Dlog_debug { "Now params are $_" } $params;
          ANNOTATION:
            foreach my $ann ($site->annotations) {
                my $aid = $ann->annotation_id;
                log_debug { "Checking $aid" };
                if ($params->{"annotation-passed-$aid"}) {
                    my %single = (value => $params->{"annotation-value-$aid"});
                    if ($params->{"annotation-wipe-$aid"}) {
                        $single{remove} = 1;
                    }
                    elsif ($ann->annotation_type eq 'file') {
                        my ($upload) = $c->request->upload("annotation-file-$aid");
                        if ($upload) {
                            $single{file} = $upload->tempname;
                            $single{value} = $upload->basename;
                        }
                        else {
                            # skip if there's nothing to do do.
                            next ANNOTATION;
                        }
                    }
                    $ann->annotate($agg, \%single);
                }
                else {
                    log_debug { "$aid not passed" };
                }
            }
            $c->flash(status_msg => $c->loc("Thanks!"));
            $agg->bump_oai_pmh_records;
            my $redirect;
            if ($params->{and_create_text}) {
                $redirect = $c->uri_for_action('/edit/newtext', ['text'],
                                               { aggregation => $agg->aggregation_id });
            }
            else {
                $redirect = $c->uri_for_action('/aggregation/aggregation',
                                               $agg->aggregation_uri);
            }
            return $c->response->redirect($redirect);
        }
        else {
            $c->flash(error_msg => $c->loc("Invalid data!"));
        }
        return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
    }
    if ($id and $id =~ /\A\d+\z/a) {
        if (my $agg = $site->aggregations->find($id)) {
            my $agg_data = $agg->serialize;
            Dlog_debug { "Data are $_" } $agg_data;
            $c->stash(
                      aggregation => $agg_data,
                      titles => [ $agg->titles ],
                     );
            if ($agg_data->{aggregation_series}) {
                $c->stash(aggregation_series_uri => $agg_data->{aggregation_series}->{aggregation_series_uri});
            }
            $self->populate_annotations($c, $agg);
        }
        else {
            return $c->detach('/not_found');
        }
    }
    else {
        $c->stash(aggregation => {});
        if (my $series_uri = $c->request->query_params->{series}) {
            if ($site->aggregation_series->by_uri($series_uri)->count) {
                $c->stash(aggregation_series_uri => $series_uri);
            }
        }
        $self->populate_annotations($c);
    }
    $c->stash(load_select2 => 1);
}

sub remove :Chained('edit_gate') :PathPart('remove') :Args(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ /\A\d+\z/a) {
        if (my $agg = $c->stash->{site}->aggregations->find($id)) {
            if ($c->check_any_user_role(qw/admin root/)) {
                $agg->bump_oai_pmh_records;
                $agg->delete;
                $c->flash(status_msg => $c->loc("Record deleted!"));
            }
            else {
                $c->flash(error_msg => $c->loc("Sorry, you can't remove this, please ask an admin"));
            }
        }
    }
    return $c->response->redirect($c->uri_for_action('/aggregation/manage'));
}

sub title :Chained('edit_gate') :PathPart('title') :Args(1) {
    my ($self, $c, $title_id) = @_;
    my $site = $c->stash->{site};
    my $ok = 0;
    my $int = qr{\A\d+\z}a;
    my $params = $c->request->body_params;
    if ($title_id =~ m/$int/) {
        if (my $title = $site->titles->texts_only->find($title_id)) {
            if ($title->aggregate($params)) {
                $c->flash(status_msg => $c->loc("Thanks!"));
            }
            return $c->response->redirect($c->uri_for($title->full_uri));
        }
    }
    $c->detach('/not_found');
}

sub show :Chained('/site') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(breadcrumbs => [
                              {
                               uri => $c->uri_for('/'),
                               label => $c->loc("Home"),
                              },
                              {
                               uri => $c->uri_for_action('/aggregation/list_aggregations'),
                               label => $c->loc("Anthologies and periodicals"),
                              }
                             ]);
}

sub list_aggregations :Chained('show') :PathPart('aggregation') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my (@anthologies, @periodicals);
    foreach my $anthology ($site->aggregations->anthologies->sorted->all) {
        push @anthologies, {
                           name => $anthology->aggregation_name,
                           url => $c->uri_for_action('/aggregation/aggregation', $anthology->aggregation_uri),
                          };
    }
    foreach my $periodical ($site->aggregation_series->sorted->all) {
        push @periodicals, {
                            name => $periodical->aggregation_series_name,
                            url => $c->uri_for_action('/aggregation/series', $periodical->aggregation_series_uri),
                           };
    }
    $c->stash(
              anthologies => \@anthologies,
              periodicals => \@periodicals,
             );
}

sub aggregation :Chained('show') :PathPart('aggregation') :Args(1) {
    my ($self, $c, $uri) = @_;
    if (my $agg = $c->stash->{site}->aggregations->find({ aggregation_uri => $uri })) {
        my @breadcrumbs;
        if (my $series = $agg->aggregation_series) {
            @breadcrumbs = ({
                             uri => $c->uri_for_action('/aggregation/series', $series->aggregation_series_uri),
                             label => $series->aggregation_series_name,
                            },
                            {
                             uri => '#',
                             label => $agg->issue,
                            });
        }
        else {
            @breadcrumbs = ({
                             uri => '#',
                             label => $agg->aggregation_name,
                            });
        }
        push @{$c->stash->{breadcrumbs}}, @breadcrumbs;
        $self->populate_node_breadcrumbs($c, $agg);
        $c->stash(
                  aggregation => $agg->final_data,
                  texts => AmuseWikiFarm::Utils::Iterator->new([
                                                                $agg->titles({ view => 1,
                                                                               public_only => !$c->user_exists })
                                                               ]),
                  categories => $agg->display_categories,
                 );
        $self->populate_annotations($c, $agg);
        Dlog_debug { "Agg is $_"  } $c->stash->{aggregation};
    }
    else {
        $c->detach('/not_found');
    }
}

sub series :Chained('show') :PathPart('series') :Args(1) {
    my ($self, $c, $code) = @_;
    if (my $series = $c->stash->{site}->aggregation_series->find({ aggregation_series_uri => $code })) {
        push @{$c->stash->{breadcrumbs}},
          {
           uri => '#',
           label => $series->aggregation_series_name,
          };
        $self->populate_node_breadcrumbs($c, $series);
        $c->stash(
                  aggregations => [ map { $_->final_data } $series->aggregations->sorted ],
                  series => $series,
                 );
    }
    else {
        $c->detach('/not_found');
    }
}

sub populate_node_breadcrumbs :Private {
    my ($self, $c, $obj) = @_;
    if (my @nodes = $obj->nodes->sorted->all) {
        my $lang = $c->stash->{current_locale_code} || 'en';
        my @node_breadcrumbs = map { $_->breadcrumbs($lang) } @nodes;
        foreach my $nbc (@node_breadcrumbs) {
            push @$nbc, {
                         uri => $obj->full_uri,
                         label => encode_entities($obj->final_name),
                        };
        }
        $c->stash(node_breadcrumbs => \@node_breadcrumbs);
    }
}

sub populate_annotations :Private {
    my ($self, $c, $agg) = @_;
    my $ann_rs = $c->stash->{site}->annotations->active_only;
    # mutatis mutandis AmuseWikiFarm::Role::Controller::Text
    unless ($c->user_exists) {
        $ann_rs = $ann_rs->public_only;
    }
    my @annotations;
    foreach my $ann ($ann_rs->sorted->all) {
        push @annotations, $ann->values_for_object($agg, $c->uri_for('/'));
    }
    $c->stash(annotations => \@annotations);
}

__PACKAGE__->meta->make_immutable;

1;
