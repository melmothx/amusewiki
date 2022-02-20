package AmuseWikiFarm::Controller::Federation;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use Regexp::Common qw/net/;

=head1 NAME

AmuseWikiFarm::Controller::Federation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site_user_required') :PathPart('federation') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->check_any_user_role(qw/admin root/)) {
        $c->detach('/not_permitted');
        return;
    }
}

sub sources :Chained('root') :PathPart('sources') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->stash->{site}->mirror_origins;
    $c->stash(origins_rs => $rs,
              all_mirror_origins => [ $rs->all ],
              page_title => $c->loc("Federation"),
             );
}

sub show :Chained('sources') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(load_datatables => 1,
              mirror_info_src => $c->uri_for_action('/federation/local_ajax'),
             );
}

sub local_ajax :Chained('root') :PathPart('local-ajax') :Args(0) {
    my ($self, $c) = @_;
    my $data = $c->stash->{site}->mirror_infos->without_origin->detail_list;
    $c->stash(json => { data => $data });
    $c->detach($c->view('JSON'));
}

sub edit :Chained('sources') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    my %params = %{ $c->request->body_parameters };
    Dlog_debug { "Params: $_" } \%params;
    my $rs = $c->stash->{origins_rs};
    if ($params{create} && $params{remote_domain} && $params{remote_path}) {
        s/\s+//g for ($params{remote_domain}, $params{remote_domain});
        if ($params{remote_domain} =~ m/\A$RE{net}{domain}{-nospace}{-rfc1101}\z/) {
            # try to see if it's possible to get a response
            my $src = $rs->create({
                                   remote_domain => $params{remote_domain},
                                   remote_path => $params{remote_path},
                                  });
            my $got_ok = 0;
            if (my $res = $src->fetch_remote) {
                Dlog_info { $_ } $res;
                if ($res->{data}) {
                    $c->flash(status_msg => $c->loc("Added"));
                    $got_ok = 1;
                }
                else {
                    $c->flash(error_msg => $c->loc("Invalid response"));
                }
            }
            else {
                $c->flash(error_msg => $c->loc("Failure fetching the source"));
            }
            unless ($got_ok) {
                log_info { "Failed response, removing the new source" };
                $src->delete;
            }
        }
        else {
            $c->flash(error_msg => $c->loc("Invalid domain"));
        }
        $c->res->redirect($c->uri_for_action('/federation/show'));
        return;
    }
    my %out;
    if (my $edit = $params{toggle}) {
        if (my $origin = $rs->find($edit)) {
            $origin->update({ active => $origin->active ? 0 : 1 });
            $out{toggled} = $edit;
        }
        else {
            $out{error} = "$edit not found";
        }
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub single :Chained('sources') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    if (my $origin = $c->stash->{origins_rs}->find($id)) {
        $c->stash(mirror_origin => $origin);
    }
    else {
        $c->detach('/not_found');        
    }
}

sub details :Chained('single') :PathPart('details') :Args(0) {
    my ($self, $c) = @_;
    my $origin = $c->stash->{mirror_origin};
    $c->stash(
              mirror_info_src => $c->uri_for_action('/federation/ajax', [ $origin->mirror_origin_id ]),
              load_datatables => 1,
             );
}

sub ajax :Chained('single') :PathPart('ajax') :Args(0) {
    my ($self, $c) = @_;
    my $origin = $c->stash->{mirror_origin};
    my $data = $origin->mirror_infos->detail_list;
    $c->stash(json => { data => $data });
    $c->detach($c->view('JSON'));
}


sub check :Chained('single') :PathPart('check') :Args(0) {
    my ($self, $c) = @_;
    my $origin = $c->stash->{mirror_origin};
    my $res = $origin->fetch_remote;
    $c->stash(json => $res);
    $c->detach($c->view('JSON'));
}

sub fetch :Chained('single') :PathPart('fetch') :Args(0) {
    my ($self, $c) = @_;
    my $res = $c->stash->{mirror_origin}->fetch_and_prepare_download;
    if (my $job = $res->{job}) {
        $c->response->redirect($c->uri_for_action('/tasks/show_bulk_job', [ $job->bulk_job_id ]));
    }
    else {
        $c->flash(error_msg => $c->loc("Error: [_1]", $res->{error} || "Unknwon error"));
        $c->response->redirect($c->uri_for_action('federation/show'));
    }
}

sub remove :Chained('single') :PathPart('remove') :Args(0) {
    my ($self, $c) = @_;
    my $origin = $c->stash->{mirror_origin};
    $origin->delete;
    $c->flash(status_msg => $c->loc("Source removed"));
    $c->response->redirect($c->uri_for_action('federation/show'));
}

sub mirror_info_edit :Chained('root') :PathPart('mirror-info-edit') :Args(0) {
    my ($self, $c) = @_;
    my %params = %{ $c->request->body_parameters || {} };
    my $site = $c->stash->{site};
    my %out;
    if ($params{id} and $params{id} =~ m/\A[0-9]+\z/) {
        if (my $target = $site->mirror_infos->find($params{id}))  {

            my $value = $params{value};

            if ($params{field} eq 'mirror_exception') {
                # update to whatever value is sent.
                $target->update({ mirror_exception => $value // ''});
                $out{ok} = 1;
            }
            elsif ($params{field} eq 'mirror_origin_id') {
                if ($value
                    and $value =~ m/\A[0-9]+\z/
                    and $site->mirror_origins->find($value)) {
                    $target->update({ mirror_origin_id => $value });
                    $out{ok} = 1;
                }
                elsif (!$value) {
                    $target->update({ mirror_origin_id => undef });
                    $out{ok} = 1;
                }
                else {
                    $out{error} = $c->loc("Invalid parameter");
                }
            }
            else {
                $out{error} = $c->loc("Invalid field");
            }
        }
        else {
            $out{error} = $c->loc("Invalid target");
        }
    }
    else {
        $out{error} = $c->loc("Invalid ID");
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
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
