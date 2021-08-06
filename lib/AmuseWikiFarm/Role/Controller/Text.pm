package AmuseWikiFarm::Role::Controller::Text;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;
requires 'base';
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';

use AmuseWikiFarm::Utils::Amuse qw//;
use HTML::Entities qw//;
use AmuseWikiFarm::Log::Contextual;

sub match :Chained('base') PathPart('') :CaptureArgs(1) {
    my ($self, $c, $arg) = @_;
    log_debug { "In match" };
    my $name = $arg;
    my $ext = '';
    my $append_ext = '';
    my $site = $c->stash->{site};

    # strip the extension
    if ($arg =~ m/(.+?) # name
                  \.   # dot
                  # and extensions we provide
                  (
                      c[0-9]+\.pdf |
                      c[0-9]+\.epub |
                      c[0-9]+\.tex |
                      a4\.pdf |
                      lt\.pdf |
                      sl\.tex |
                      sl\.pdf |
                      pdf     |
                      html    |
                      tex     |
                      epub    |
                      muse    |
                      zip     |

                      # these two need special treatment
                      jpe?g   |
                      png
                  )$
                 /x) {
        $name = $1;
        $ext  = $2;
    }

    log_debug { "Ext is $ext, name is $name" };

    if ($ext) {
        $append_ext = '.' . $ext;
    }

    # assert we are using canonical names.
    my $canonical = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($name);
    log_debug { "canonical is $canonical" };

    # find the title or the attachment
    if (my $text = $c->stash->{texts_rs}->single({ uri => $canonical})) {
        $c->stash(text => $text);
        if ($canonical ne $name) {
            my $location = $c->uri_for($text->full_uri);
            $c->response->redirect($location, 301);
            $c->detach();
            return;
        }
        my $show_preview_only = 0;
        if (!$text->is_published) {
            # Double check
            die "This shouldn't happen, status is wrong " . $text->status unless $text->is_deferred;

            # but we're here so either we're logged in or we show only
            # the preview.
            if (!$c->user_exists and $site->show_preview_when_deferred) {
                $show_preview_only = 1;
            }
            elsif ($c->user_exists) {
                $show_preview_only = 0;
            }
            else {
                # shoulnt' be reachable.
                die "User doesn't exist but we are here";
            }
        }
        # static files are served here
        # no download if the files are in preview only
        if ($ext) {
            log_debug { "Got $canonical $ext => " . $text->title };
            my $served_file = $text->filepath_for_ext($ext);
            if (!$show_preview_only and -f $served_file) {
                # https://support.google.com/webmasters/answer/93710?hl=en
                $c->response->header('X-Robots-Tag' => 'noindex');
                $c->stash(serve_static_file => $served_file);
                $c->detach($c->view('StaticFile'));
                return;
            }
            else {
                $c->detach('/not_found');
                return;
            }
        }
        $c->stash(page_title => HTML::Entities::decode_entities($text->title),
                  text_json_api => $c->uri_for($text->full_header_api),
                  show_preview_only => $show_preview_only);
    }
    elsif (my $attach = $site->attachments->by_uri($canonical . $append_ext)) {
        log_debug { "Found attachment $canonical$append_ext" };
        $c->stash(serve_static_file => $attach->f_full_path_name);
        $c->detach($c->view('StaticFile'));
        return;
    }
    else {
        $c->stash(uri => $canonical);
        my $unavailable_text = $site->titles->find({
                                                    f_class => $c->stash->{f_class} || '',
                                                    uri => $canonical,
                                                   });
        if ($unavailable_text and $c->user_exists) {
            $c->response->redirect($c->uri_for_action('/console/unpublished'));
            $c->detach();
        }
        elsif ($unavailable_text and $unavailable_text->is_gone) {
            $c->detach('/gone');
        }
        else {
            $c->detach('/not_found');
        }
    }
}

sub populate_preamble :Chained('match') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $text = $c->stash->{text};
    my $site = $c->stash->{site};
    my $current_uri = $text->full_uri;
    $c->stash(
              text_display_categories => $text->display_categories
             );
    my $rs = $text->children_texts;
    if (my $parent = $text->parent_text) {
        if ($parent->is_published or
            ($parent->is_deferred and ($c->user_exists or $site->show_preview_when_deferred))) {
            # use the parent to fetch the children
            $rs = $parent->children_texts;
            $c->stash(text_display_parent => {
                                              full_uri => $parent->full_uri,
                                              title => $parent->title,
                                             });
        }
    }
    if ($c->user_exists or $site->show_preview_when_deferred) {
        $rs = $rs->status_is_published_or_deferred;
    }
    else {
        $rs = $rs->status_is_published;
    }
    if (my @children = $rs->ordered_by_uri->all) {
        my @out;
        foreach my $child (@children) {
            my %info = (
                        author   => $child->author,
                        full_uri => $child->full_uri,
                        title    => $child->title,
                        subtitle => $child->subtitle,
                       );
            if ($info{full_uri} eq $current_uri) {
                $info{active} = 1;
            }
            push @out, \%info;
        }
        $c->stash(text_display_children => \@out);
    }
}

sub text :Chained('populate_preamble') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $text = $c->stash->{text};
    my $site = $c->stash->{site};
    $c->stash(template => 'text.tt',
              load_highlight => $site->use_js_highlight);
    if ($c->stash->{blog_style} && $text->is_regular) {
        if (my $next_text = $text->newer_text) {
            $c->stash(text_next_uri => $next_text->full_uri);
        }
        if (my $prev_text = $text->older_text) {
            $c->stash(text_prev_uri => $prev_text->full_uri);
        }
    }
    my $meta_desc = '';
    if (my $teaser = $text->teaser) {
        # do not insert teasers if they're too long
        if (length($teaser) < 160) {
            $meta_desc = $teaser;
        }
    }
    unless ($meta_desc) {
      TEXTFIELD:
        foreach my $method (qw/author title subtitle date notes/) {
            if (my $info = $text->$method) {
                $meta_desc .= $info . " ";
            }
            last TEXTFIELD if length($meta_desc) > 160;
        }
    }
    $c->stash(meta_description => $meta_desc);
    if (my @attachments = $text->attached_objects) {
        my @out;
        my $is_gallery = @attachments > 1 ? 1 : 0;
        my $count = 0;
        while (@attachments) {
            $count++;
            my $att = shift @attachments;
            push @out, $att;
            unless ($count % 3) {
                push @out, { separator => 1 } if @attachments;
            }
        }
        Dlog_debug { "PDFs: $_" } \@out;
        $c->stash(attached_pdfs => \@out,
                  attached_pdfs_gallery => $is_gallery);
    }
    if ($site->enable_backlinks) {
        my @backlinks;
        foreach my $backlink ($text->backlinks) {
            push @backlinks, {
                              uri => $c->uri_for($backlink->full_uri)->as_string,
                              title => $backlink->title,
                              author => $backlink->author,
                              lang => $backlink->lang,
                             };
        }
        if (@backlinks) {
            Dlog_debug { "backlinks: $_" } \@backlinks;
            $c->stash(text_backlinks => \@backlinks);
        }
    }
    if (my @nodes = $text->nodes->sorted->all) {
        my $lang = $c->stash->{current_locale_code} || 'en';
        my @node_breadcrumbs = map { $_->breadcrumbs($lang) } @nodes;
        foreach my $nbc (@node_breadcrumbs) {
            push @$nbc, {
                         uri => $text->full_uri,
                         label => $text->title,
                        };
        }
        $c->stash(node_breadcrumbs => \@node_breadcrumbs);
    }
    $c->response->headers->last_modified($text->f_timestamp_epoch || time());
}

sub edit :Chained('match') PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In edit" };
    my $text = $c->stash->{text};
    $c->response->redirect($c->uri_for_action('/edit/revs', [$text->f_class,
                                                             $text->uri]));
}

sub json :Chained('match') PathPart('json') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(json => $c->stash->{text}->raw_headers);
    $c->detach($c->view('JSON'));
}

sub mirror_manifest :Chained('match') PathPart('manifest.json') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(json => $c->stash->{text}->mirror_manifest);
    $c->detach($c->view('JSON'));
}

sub toc :Chained('match') PathPart('toc') :Args(0) {
    my ($self, $c) = @_;
    my @struct = $c->stash->{text}->text_parts->ordered->toc_entries->hri;
    $_->{prefix} = '*' x $_->{part_level} for @struct;
    $c->stash(no_wrapper => 1,
              toc => \@struct,
              template => 'library/toc.tt',
             );
}

sub embed :Chained('populate_preamble') PathPart('embed') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(no_wrapper => 1,
              bootstrap_css => "/static/css/bootstrap." . $c->stash->{site}->bootstrap_theme . ".css",
              template => 'library/embed.tt');
}

sub rebuild :Chained('match') PathPart('rebuild') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In rebuild" };
    die unless $self->check_login($c);
    # please note that here we rebuild the text even if it's not a
    # post action. It could be argued that an action like this needs a
    # post. However, a get lets us trigger the recompile on specials
    # as well, where the form is not visible. Also, here the data is
    # not really changed. Let's consider it more a cache rebuilding.
    my $text = $c->stash->{text};
    my $job = $c->stash->{site}->jobs->rebuild_add({ id => $text->id }, $c->user->get('username'));
    $c->res->redirect($c->uri_for_action('/tasks/display',
                                         [ $job->id ]));
}

1;
