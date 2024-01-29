package AmuseWikiFarm::Controller::BookCovers;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use DateTime;
use AmuseWikiFarm::Utils::Amuse;

sub bookcovers :Chained('/site_human_required') :PathPart('bookcovers') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(breadcrumbs => [
                              {
                               uri => $c->uri_for_action('/bookcovers/listing'),
                               label => $c->loc("Book Covers"),
                              }
                             ]);
}

sub create :Chained('bookcovers') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;
    # add the user
    my %values = (
                  created => DateTime->now(time_zone => 'UTC'),
                  session_id => $c->sessionid,
                  language_code => $c->stash->{current_locale_code},
                  $c->user_exists ? (user_id => $c->user->id) : (),
                 );
    if (my $template = $c->request->params->{template}) {
        $values{template} = "$template";
    }
    my $bc = $c->stash->{site}->bookcovers->create_and_initalize(\%values);
    $c->response->redirect($c->uri_for_action('/bookcovers/edit', [ $bc->bookcover_id ]));
}

sub resultset :Chained('bookcovers') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs;
    if ($c->user_exists) {
        if ($c->check_user_roles('root')) {
            # any
            $rs = $c->model('DB::Bookcover');
        }
        elsif ($c->check_user_roles('admin')) {
            # site's covers
            $rs = $c->stash->{site}->bookcovers;
        }
        else {
            # user's covers
            $rs = $c->user->get_object->bookcovers;
        }
    }
    elsif (my $sid = $c->sessionid) {
        # otherwise session's ones
        $rs = $c->stash->{site}->bookcovers->search({
                                                     session_id => $sid,
                                                    });
    }
    if ($rs) {
        $c->stash(bookcovers_rs => $rs);
    }
    else {
        $c->detach('/not_found');
    }
}

sub listing :Chained('resultset') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(bookcovers => [ $c->stash->{bookcovers_rs}->all ],
              load_datatables => 1,
             );
}

sub find :Chained('resultset') :PathPart('bc') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ m/\A\d+\z/a) {
        if (my $bc = $c->stash->{bookcovers_rs}->find($id)) {
            $c->stash(bookcover => $bc);
            return;
        }
    }
    $c->detach('/not_found');
}

sub edit :Chained('find') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $bc = $c->stash->{bookcover};
    # shouldn't happen.
    return $c->detach('/not_found') unless $bc;

    $c->stash(bookcover_tokens => [ $bc->bookcover_tokens->search(undef, { order_by => 'token_name' }) ]);

    push @{$c->stash->{breadcrumbs}},
      {
       uri => $c->uri_for_action('/bookcovers/edit', [ $bc->bookcover_id ]),
       label => $c->loc('Edit'),
      };
    my %params = %{$c->request->body_params};
    # post request
    if (%params) {
        my $tokens = $bc->parse_template;
        my $wd = $bc->working_dir;
        # should always be fine.
        if (-d $wd) {
            my $fi = 1;
            foreach my $up (grep { $_->{type} eq 'file' } values %$tokens) {
                delete $params{$up->{full_name}};
                my ($upload) = $c->request->upload($up->{full_name});
                if ($upload) {
                    my $file = $upload->tempname;
                    my $mime_type = AmuseWikiFarm::Utils::Amuse::mimetype($file);
                    log_info { "provided $file $mime_type" };
                    if ($mime_type =~ m/(pdf|jpe?g|png)\z/) {
                        my $ext = $1;
                        my $fname = "f" . $fi++ . "." . $ext;
                        my $target = $wd->child($fname);
                        log_info { "Saving file into $target" };
                        if ($upload->copy_to("$target")) {
                            $params{$up->{full_name}} = $fname;
                        }
                    }
                }
            }
        }
        else {
            log_error { "$wd does not exists!" };
        }
        # TODO handle uploads here
        $bc->update_from_params(\%params);
        if ($params{build}) {
            my $job = $site->jobs->enqueue(build_bookcover => {
                                                               id => $bc->bookcover_id,
                                                              }, $bc->username);
            $c->res->redirect($c->uri_for_action('/tasks/display',
                                                 [$job->id]));
        }
    }
}

sub download :Chained('find') :PathPart('download') :Args {
    my ($self, $c, $type) = @_;
    if (my $bc = $c->stash->{bookcover}) {
        if ($bc->compiled) {
            if ($type =~ m/\.zip\z/) {
                if (my $path = $bc->zip_path) {
                    $c->stash(serve_static_file => $path);
                    $c->detach($c->view('StaticFile'));
                    return;
                }
            }
            elsif ($type =~ m/\.pdf\z/) {
                if (my $path = $bc->pdf_path) {
                    $c->stash(serve_static_file => $path);
                    $c->detach($c->view('StaticFile'));
                    return;
                }
            }
        }
    }
    return $c->detach('/not_found');
}

sub remove :Chained('find') :PathPart('remove') :Args(0) {
    my ($self, $c, $type) = @_;
    if ($c->request->body_params->{remove}) {
        if (my $bc = $c->stash->{bookcover}) {
            $c->flash(status_msg => $c->loc("Cover removed"));
            $bc->delete;
        }
    }
    $c->res->redirect($c->uri_for_action('/bookcovers/listing'));
}

sub clone :Chained('find') :PathPart('clone') :Args(0) {
    my ($self, $c) = @_;
    if (my $src = $c->stash->{bookcover}) {
        my %values = $src->get_columns;
        foreach my $f (qw/created session_id
                          user_id bookcover_id
                          compiled
                          zip_path
                          pdf_path
                         /) {
            delete $values{$f};
        }
        $values{created} = DateTime->now(time_zone => 'UTC');
        $values{session_id} = $c->sessionid;
        if ($c->user_exists) {
            $values{user_id} = $c->user->id;
        }
        my $bc = $c->stash->{site}->bookcovers->create_and_initalize(\%values);
        $c->response->redirect($c->uri_for_action('/bookcovers/edit', [ $bc->bookcover_id ]));
        return;
    }
    return $c->detach('/not_found');
}

sub attached :Chained('find') :PathPart('attached') :Args(1) {
    my ($self, $c, $fname) = @_;
    if (my $src = $c->stash->{bookcover}) {
        if ($fname =~ m/\A(f\d+\.(pdf|png|jpe?g)|isbn-[0-9-]+\.pdf)\z/) {
            my $file = $src->working_dir->child($fname);
            if ($file->exists) {
                $c->stash(serve_static_file => "$file");
                $c->detach($c->view('StaticFile'));
            }
        }
    }
    return $c->detach('/not_found');
}

__PACKAGE__->meta->make_immutable;

1;
