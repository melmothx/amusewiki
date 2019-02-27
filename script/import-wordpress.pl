#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use URI;
use AmuseWikiFarm::Schema;
use WordPress::DBIC::Schema;
use Data::Dumper::Concise;
use Date::Parse;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
use File::Temp;
use LWP::UserAgent;
use File::Spec;
use Getopt::Long;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;

my %opts;

GetOptions(\%opts,
           'post=i',
           'parent=i',
           'grandparent=i',
           'sku-prefix=s',
           'topic-prefix=s',
           'merge-children=s',
           'skip-main',
          ) or die;

binmode STDOUT, ':encoding(UTF-8)';

my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.1');
my ($site_id, $hostname, $lang) = @ARGV;
$lang ||= 'en';
die "2 arguments required: site_id and hostname" unless $site_id && $hostname;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find($site_id) or die "Cannot find site id $site_id!";
my $email = $site->mail_notify;
$site->update({ mail_notify => undef });
my $wp = WordPress::DBIC::Schema->connect('wordpress');
my $topic_prefix = $opts{'topic-prefix'} || '';
my $sku_prefix = $opts{'sku-prefix'} || '';

if ($opts{'skip-main'}) {
    if ($opts{grandparent}) {
        if ($opts{'merge-children'}) {
            collect_children($opts{grandparent}, $opts{'merge-children'});
        }
    }
    exit;
}


print "Reimporting\n";
$site->titles->delete;
$site->categories->delete;
$site->legacy_links->delete;
$site->attachments->delete;
path($site->repo_root)->remove_tree({ safe => 0 });
$site->initialize_git;
$site->jobs->delete;


my $posts = $wp->resultset('WpPost');

if ($opts{grandparent}) {
    $posts = $posts
      ->search({ 'me.post_parent' => $opts{grandparent} })
      ->search_related(children => undef, {
                                           order_by => ['me.menu_order', 'children.menu_order'],
                                          });
}
elsif($opts{parent}) {
    $posts = $posts->search({ post_parent => $opts{parent} },
                            {
                             order_by => ['menu_order']
                            });
}
elsif ($opts{post}) {
    $posts = $posts->search({ id => $opts{post} });
}

$posts = $posts->published;

my @errors;

print "Total " . $posts->count . " posts\n";

while (my $post = $posts->next) {
    print $post->clean_url . "\n";
    my $parent = $post->parent;
    my $topic = $parent->post_title || $parent->post_name || die "Missing parent name!";
    $topic =~ s/;/,/g;
    my %out = (
               uri => $parent->post_name . '-' . $post->post_name,
               sku => $sku_prefix . sprintf('%.4d-%.8d-%.4d-%.8d',
                                            $parent->menu_order, $parent->id, $post->menu_order, $post->id),
               title => $post->post_title,
               SORTtopics => $topic_prefix . $topic . ';',
               lang => $lang,
               notes => $topic_prefix . $topic,
              );
    if (my $date = $post->post_date) {
        $out{pubdate} = $date->ymd;
    }
    if (my $subtitle = $post->metas->search({ meta_key => 'subtitle'})->first) {
        $out{subtitle} = $subtitle->meta_value;
    }
    my @authors = map { $_->wp_term->name } $post->taxonomies->search({ taxonomy => { -like => '%author' } });
    if (@authors) {
        $out{author} = join(' <br> ', @authors);
        $out{SORTauthors} = join(' ;', @authors) . ';';
    }
    $out{source} = '[[https://' . $hostname . $post->clean_url . ']]';
    $out{textbody} = $post->html_body;

    my @links = grep { $_ } ($post->clean_url, $post->permalink);

    if ($out{textbody} =~ m/\[child-pages.*?\]/) {
        # reset the body, we're interested only in the content. Too bad for the image.
        $out{textbody} = '';
        foreach my $child ($post->children->published->search({
                                                               post_type => [qw/page/],
                                                              },
                                                              {
                                                               order_by => [qw/menu_order post_name/],
                                                              })->all) {

            $out{textbody} .= "<h2>" . $child->post_title;
            if (my @cauths = map { $_->wp_term->name } $child->taxonomies->search({ taxonomy => { -like => '%author' } })) {
                $out{textbody} .= " <em>(" . join(", ", @cauths) . ")</em>";
            }

            $out{textbody} .= "</h2>";
            if (my $subt = $child->metas->search({ meta_key => 'subtitle'})->first) {
                $out{textbody} .= "<h3>" .  $subt->meta_value . "</h3>";
            }
            $out{textbody} .= "<div>" . $child->html_body . "</div>";
            push @links, $child->clean_url, $child->permalink;
        }
    }
    $out{textbody} =~ s/<strong>(.*?<img .*?>.*?)<\/strong>/$1/g;
    $out{textbody} =~ s/(<h.>.*?)(<img .*?>)(.*?<\/h.>)/$1$2$3/g;
    add_text(\%out, \@links);
}

print Dumper(\@errors) if @errors;

sub collect_children {
    my ($parent, $page_name) = @_;
    my $parents = $wp->resultset('WpPost')->published->search({ post_parent => $parent },
                                                              {
                                                               order_by => ['menu_order']
                                                              });
    $site->titles->search({ f_class => 'special', title => $page_name })->delete;
    my ($revision, $error) = $site->create_new_text({ title => $page_name }, 'special');
    die $error if $error;
    my $muse = $revision->muse_body;
    my @topics;
    my $imgcounter = 0;
    my $tmp = File::Temp->newdir;
    while (my $post = $parents->next) {
        my %images;
        my %downloads;
        my $html = $post->post_content;
      IMAGE:
        while ($html =~ m/(https?:\/\/\Q$hostname\E\/wp-content\/uploads\/[0-9a-zA-Z\.\/\-]*\.(gif|png|jpe?g))/g) {
            my $img = $1;
            my $ext = $2;
            if ($img !~ m/\d+x\d+\.(png|gif|jpe?g)$/) {
                $downloads{$img}++;
                next IMAGE if $downloads{$img} > 1;
                my $local = download_image($img) or die "Couldn't download $img";
                my $got = $revision->add_attachment($local);
                die Dumper($got) unless $got->{attachment};
                $images{$got->{attachment}}++;
            }
        }
        $muse .= "\n\n** " . $topic_prefix . $post->post_title . "\n\n";

        if (%images) {
            my $name = $topic_prefix . ($post->post_title || $post->post_name);
            my @images = keys %images;
            my $desc;
            foreach my $img (@images) {
                $muse .= "\n[[$img][$name]]\n";
                $desc .= "\n[[$img f]]\n";
            }
            if (my $c = $site->categories->single({ uri => muse_naming_algo($name), type => 'topic' })) {
                $c->category_descriptions->update_description(en => $desc);
            }
            else {
                print "Skipping $desc for $name\n";
            }
        }

        foreach my $art ($post->children->published->search(undef, {
                                                                    order_by => [qw/menu_order post_name/],
                                                                   })->all) {
            $muse .= "\n\n[[" . $art->clean_url . "][" . $art->post_title . "]]\n\n";
        }
    }
    $revision->edit({ body => $muse });
    $revision->commit_version;
    $revision->publish_text;
}

if ($opts{grandparent}) {
    if ($opts{'merge-children'}) {
        collect_children($opts{grandparent}, $opts{'merge-children'});
    }
}

$site->update({ mail_notify => $email });

print "Done. Generating indexes now\n";
if (my $j = $site->jobs->search({ task => 'build_static_indexes' })->dequeue) {
    $j->dispatch_job;
}


sub add_text {
    my ($text, $links) = @_;
    die unless $text;
    my ($revision) = $site->create_new_text($text, 'text');
    if (my $cover = $text->{cover}) {
        my $target = File::Spec->catfile('out.png');
        if (system(convert => -resize => '300x300',
                   URI->new($cover)->canonical, $target) == 0) {
            if (my $cover_uri = $revision->add_attachment($target)->{attachment}) {
                $text->{cover} = $cover_uri;
            }
            else {
                warn "Failed to upload the cover!\n";
                delete $text->{cover};
            }
        }
        else {
            warn "Fetching $cover failed!";
            delete $text->{cover};
        }
    }
    my $muse = $revision->muse_body;

    # cleaning
    $muse =~ s/\s+\]\]/]]/sg;
    $muse =~ s/\]\[\]\]/]]/sg;
    $muse =~ s/\s*\z//;

    my @pdfs;
    $muse =~ s!
           \[\[
           (https?://\Q$hostname\E/[^\]]*?\.(gif|pdf|png|jpe?g))\]
           (\[.*?\])?
           \]!attach_to_text($revision, $1, $3, \@pdfs)!igex;

    $muse =~ s/\[caption(.*?)\]
               (.*?)
               (\[\[.+?\]\])
               (.*?)
               \[\/caption\]/handle_caption($1, $2, $3, $4)/sgex;

    if (@pdfs) {
        $muse = "#ATTACH " . join(' ', @pdfs) . "\n" . $muse . "\n";
    }

    $muse =~ s/<strong>\s*<\/strong>//gs;
    $muse =~ s/<em>\s*<\/em>//gs;
    $muse =~ s/^\*+ *$//gm;

    $revision->edit({
                     body => $muse,
                     fix_typography => 1,
                    });
    $revision->commit_version;
    my $new_uri = $revision->publish_text;
    print "New uri is $new_uri\n";
    if ($links) {
        foreach my $old (@$links) {
            $site->add_to_legacy_links({
                                        legacy_path => $old,
                                        new_path => $new_uri,
                                       });
        }
    }
}

sub attach_to_text {
    my ($rev, $url, $desc, $pdfs) = @_;
    $desc ||= '';
    die unless $rev && $url;
    print "Replacing $url $desc\n";
    my $tmp = File::Temp->newdir;
    my $local;
    if ($url =~ m/\.pdf$/) {
        $local = File::Spec->catfile($tmp, 'out.pdf');
        $ua->mirror($url, $local);
    }
    else {
        $local = download_image($url) or die "$url wasn't downloaded";
    }
    my $got = $rev->add_attachment($local);
    if ($got->{error}) {
        warn "FAILED to add $local file";
        push @errors, "FAILED to add $local file" . Dumper($got);
        return $desc;
    }
    die unless $got->{attachment};
    if ($got->{attachment} =~ m/\.pdf$/) {
        push @$pdfs, $got->{attachment};
        $got->{attachment} = '#amw-attached-pdfs';
    }
    print "Attaching $got->{attachment}\n";
    return "\n\n[[" . $got->{attachment} . "]$desc]\n\n";
}

sub handle_caption {
    my ($args, $before, $url, $after) = @_;
    $before //= '';
    $after  //= '';
    # it already has a caption, just return everything.
    if ($url =~ m/\]\[/) {
        return $before . $url . $after;
    }
    else {
        my $desc = $before . $after;
        $desc =~ s/\s+/ /g;
        $desc =~ s/\A\s*//;
        $desc =~ s/\s*\z//;
        $desc = '[' . $desc . ']]';
        if ($args =~ m/right/) {
            $desc = ' r]' . $desc;
        }
        elsif ($args =~ m/left/) {
            $desc = ' l]' . $desc;
        }
        else {
            $desc = ' f]' . $desc;
        }
        $url =~ s/\]\]\z/$desc/;
        return "\n$url\n";
    }
}

sub download_image {
    my $img = shift;
    my $destdir = path('image-cache');
    $destdir->mkpath;
    if ($img =~ m/(https?:\/\/\Q$hostname\E\/(.+\.(gif|png|jpe?g)))/i) {
        my $base = $2;
        my $ext  = $3;
        $base =~ s/[^a-zA-Z0-9]/_/g;
        my $local = $destdir->child($base . '.local.png');
        my $mirrored = $destdir->child($base . '.orig.' . $ext);
        if ($local->exists) {
            print "$local already exists, reusing\n";
        }
        else {
            print "Fetching $img and saving into $local\n";
            $ua->mirror($img, "$mirrored");
            die "Failure to download $img into $mirrored" unless $mirrored->exists;
            die "Failed to convert $mirrored to $local" if system(convert => -strip => "$mirrored", "$local") != 0;
            die "No $local produced" unless $local->exists;
        }
        return "$local";
    }
    else {
        die "$img doesn't match";
    }
    return;
}
