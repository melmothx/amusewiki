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
use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path muse_naming_algo/;

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
my $repo = path(repo => $site_id);
$lang ||= 'en';
die "2 arguments required: site_id and hostname" unless $site_id && $hostname;

my $wp = WordPress::DBIC::Schema->connect('wordpress');
my $topic_prefix = $opts{'topic-prefix'} || '';
my $sku_prefix = $opts{'sku-prefix'} || '';

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

unless ($opts{'skip-main'}) {
    my $count = 0;
    while (my $post = $posts->next) {
        if (++$count % 100 == 0) {
            print "Done $count\n";
        }
        import_post($post) 
    }
}


sub import_post {
    my ($post, $opts) = @_;
    # print $post->clean_url . "\n";
    my $parent = $post->parent;
    my $topic = $parent->post_title || $parent->post_name || die "Missing parent name!";
    $topic =~ s/;/,/g;
    my %out = (
               uri => muse_naming_algo($parent->post_name . '-' . $post->post_name),
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
        print "Collecting child pages\n";
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
    $out{textbody} =~ s/(?:<a .*?>)(<img .*?>)(?:<\/a>)/$1/g;
    $out{textbody} =~ s/<strong>(.*?<img .*?>.*?)<\/strong>/$1/g;
    $out{textbody} =~ s/(<h.>.*?)(<img .*?>)(.*?<\/h.>)/$1$2$3/g;

    # print Dumper(\%out);
    parse_html(\%out);
    #add_text(\%out, \@links);
}

print Dumper(\@errors) if @errors;


if ($opts{grandparent}) {
    if (my $title = $opts{'merge-children'}) {
        my $tops = $wp->resultset('WpPost')->published->search({ post_parent => $opts{grandparent} },
                                                               { order_by => ['menu_order'] });

        # this section is just to build topic descriptions. Parse so
        # we save them somewhere. The muse itself could be published
        # as a poor man's category description, though.
        # there's the need for the legacy mapping though

        while (my $top = $tops->next) {
            my $html = $top->html_body;
            my @lines;
            while ($html =~ m/(<img[^>]+?>)/g) {
                push @lines, $1;
            }
            foreach my $art ($top->children->published->search(undef, {
                                                                       order_by => [qw/menu_order post_name/],
                                                                      })->all) {
                push @lines, sprintf('<p><a href="%s">%s</a></p>', $art->clean_url, $art->post_title);
            }

            my %post = (
                        uri => muse_naming_algo($title . '-' . $top->post_name),
                        title => $topic_prefix . $top->post_title,
                        textbody => join("\n\n", @lines),
                        SORTtopics => $title,
                        DELETED => "Not needed",
                       );
            parse_html(\%post);
            # now we can provide the list of legacy urls and build the topic descriptions
        }
    }
}

# $site->update({ mail_notify => $email });
# 
# print "Done. Generating indexes now\n";
# if (my $j = $site->jobs->search({ task => 'build_static_indexes' })->dequeue) {
#     $j->dispatch_job;
# }


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

sub parse_html {
    my ($text) = @_;
    if (my $path = muse_get_full_path($text->{uri})) {
        my $final = path($repo, $path->[0], $path->[1], $path->[2] . '.muse');
        my $dir = $final->parent;
        my $img_basename = ($path->[1]);
        $img_basename =~ s/\A(.)(.)\z/$1-$2/;
        $dir->mkpath unless -d $dir;
        # print "$final\n";
        my $html = delete $text->{textbody};
        $html =~ s/(<img[^>]+?>)/download_and_insert_image($1, $dir, $img_basename)/igex;
        my $muse = html_to_muse($html);
        my @lines;
        foreach my $directive (qw/title subtitle author LISTtitle SORTauthors
                                  SORTtopics date uid cat
                                  slides
                                  sku
                                  source lang pubdate
                                  publisher
                                  isbn
                                  rights
                                  seriesname
                                  seriesnumber
                                  notes
                                  DELETED
                                 /) {
            my $v = $text->{$directive};
            if (defined $v) {
                $v =~ s/\r*\n/ /gs; # it's a directive, no \n
                # leading and trailing spaces
                $v =~ s/^\s*//s;
                $v =~ s/\s+$//s;
                $v =~ s/  +/ /gs; # pack the whitespaces
                if (length $v) {
                    push @lines, "#${directive} $v";
                }
            }
        }
        # cleaning
        $muse =~ s/\s+\]\]/]]/sg;
        $muse =~ s/\]\[\]\]/]]/sg;
        $muse =~ s/\s*\z//;

        $muse =~ s/\[caption(.*?)\]
                   (.*?)
                   (\[\[.+?\]\])
                   (.*?)
                   \[\/caption\]/handle_caption($1, $2, $3, $4)/sgex;

        $muse =~ s/<strong>\s*<\/strong>//gs;
        $muse =~ s/<em>\s*<\/em>//gs;
        $muse =~ s/^\*+ *$//gm;


        my $body = join("\n", @lines, "", $muse, "");
        my $out;
        my $pp = Text::Amuse::Preprocessor->new(input => \$body, output => "$final", fix_typography => 1);
        $pp->process;
    }
    else {
        die Dumper($text);
    }

}

sub download_and_insert_image {
    my ($img, $dir, $img_basename) = @_;
    if ($img =~ m/src="(.*?)"/) {
        my $src = $1;
        my (@fragments) = split(/\//, $src);
        my $file = lc($fragments[-1]);
        $file =~ s/[^a-z0-9\.\-]//g;
        my $target = $dir->child($img_basename . '-' . $file);
        my $res = $ua->mirror($src, "$target");
        if ($res->is_success or $res->code eq '304') {
            print "Downloaded $src " . $res->code . "\n";
            return "<div>[[" . $target->basename . "]]</div>";
        }
        else {
            print "$src => " . $res->status_line . "\n";
        }
    }
    return '';
}
