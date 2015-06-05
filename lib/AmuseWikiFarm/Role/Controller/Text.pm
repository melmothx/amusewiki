package AmuseWikiFarm::Role::Controller::Text;
use MooseX::MethodAttributes::Role;
requires qw/base/;

use AmuseWikiFarm::Utils::Amuse qw//;
use HTML::Entities qw//;


sub match :Chained('base') PathPart('') :CaptureArgs(1) {
    my ($self, $c, $arg) = @_;
    $c->log->debug("In match");
    my $name = $arg;
    my $ext = '';
    my $append_ext = '';
    my $site = $c->stash->{site};

    # strip the extension
    if ($arg =~ m/(.+?) # name
                  \.   # dot
                  # and extensions we provide
                  (
                      a4\.pdf |
                      lt\.pdf |
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

    $c->log->debug("Ext is $ext, name is $name");

    if ($ext) {
        $append_ext = '.' . $ext;

        my %managed = $site->available_text_exts;
        if (exists $managed{$append_ext}) {
            unless ($managed{$append_ext}) {
                $c->log->debug("$ext is not provided");
                $c->detach('/not_found');
            }
        }
    }

    # assert we are using canonical names.
    my $canonical = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($name);
    $c->log->debug("canonical is $canonical");

    # find the title or the attachment
    if (my $text = $c->stash->{texts_rs}->find({ uri => $canonical})) {
        $c->stash(text => $text);
        if ($canonical ne $name) {
            my $location = $c->uri_for($text->full_uri);
            $c->response->redirect($location, 301);
            $c->detach();
            return;
        }
        # static files are served here
        if ($ext) {
            $c->log->debug("Got $canonical $ext => " . $text->title);
            my $served_file = $text->filepath_for_ext($ext);
            if (-f $served_file) {
                $c->stash(serve_static_file => $served_file);
                $c->detach($c->view('StaticFile'));
                return;
            }
            else {
                # this should not happen
                $c->log->warn("File $served_file expected but not found!");
                $c->detach('/not_found');
                return;
            }
        }
    }
    elsif (my $attach = $site->attachments->by_uri($canonical . $append_ext)) {
        $c->log->debug("Found attachment $canonical$append_ext");
        if ($name ne $canonical) {
            $c->log->warn("Using $canonical instead of $name, shouldn't happen");
        }
        $c->stash(serve_static_file => $attach->f_full_path_name);
        $c->detach($c->view('StaticFile'));
        return;
    }
    else {
        $c->stash(uri => $canonical);
        $c->detach('/not_found');
    }
}

sub text :Chained('match') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->log->debug("In text");
    if ($c->stash->{f_class} eq 'special') {
        $c->stash(latest_entries => [ $c->stash->{site}->latest_entries ]);
    }
    my $text = $c->stash->{text} or die "WTF?";
    $c->stash(
              template => 'text.tt',
              text => $text,
              page_title => HTML::Entities::decode_entities($text->title),
             );
    foreach my $listing (qw/authors topics/) {
        my @list;
        my $categories = $text->$listing;
        while (my $cat = $categories->next) {
            push @list, {
                         uri => $cat->full_uri,
                         name => $cat->name,
                        };
        }
        $c->stash("text_$listing" => \@list);
    }
}

sub edit :Chained('match') PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    $c->log->debug("In edit");
    my $text = $c->stash->{text};
    $c->response->redirect($c->uri_for_action('/edit/revs', [$text->f_class,
                                                             $text->uri]));
}

1;
