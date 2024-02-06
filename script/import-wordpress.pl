#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use URI;
use WordPress::DBIC::Schema;
use Data::Dumper::Concise;
use Date::Parse;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
use File::Temp;
use LWP::UserAgent;
use File::Spec;
use Getopt::Long;
use Path::Tiny;
use Text::Amuse::Preprocessor;
use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path muse_naming_algo/;
use YAML qw/DumpFile/;

my %opts;

GetOptions(\%opts,
           'post=i',
           'parent=i',
           'grandparent=i',
           'merge-children=s',
           'skip-main',
           'no-image-download',
           'series-name=s',
          ) or die;

binmode STDOUT, ':encoding(UTF-8)';

my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.1');
my ($site_id, $hostname, $lang) = @ARGV;
my $repo = path(repo => $site_id);
$lang ||= 'en';
die "2 arguments required: site_id and hostname" unless $site_id && $hostname;

my $wp = WordPress::DBIC::Schema->connect('wordpress');

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

my $series_name = $opts{'series-name'};
my $series_uri = muse_naming_algo($series_name);
my $agg_prefix = lc(join("", map { substr($_, 0, 1) } grep { $_ } split(/\s+/, $series_name)));
print "$series_name $series_uri $agg_prefix\n";

my %aggregations;

my $count = 0;
unless ($opts{'skip-main'}) {
    while (my $post = $posts->next) {
        if (++$count % 100 == 0) {
            print "Done $count\n";
        }
        import_post($post);
    }
}
my $autoimport_dir = path($repo, site_files => 'autoimport');
$autoimport_dir->mkpath;


sub import_post {
    my ($post, $opts) = @_;
    # print $post->clean_url . "\n";
    my $parent = $post->parent;
    my $issue = $parent->post_title || $parent->post_name || die "Missing parent name!";
    my %out = (
               uri => muse_naming_algo($parent->post_name . '-' . $post->post_name),
               title => $post->post_title,
               lang => $lang,
               notes => $series_name . ' #' . $issue,
              );

    $aggregations{$parent->id} ||= {
                                titles => [],
                                sorting_pos => $parent->menu_order,
                                aggregation_uri => muse_naming_algo($agg_prefix . ' ' . $issue . ' ' . $parent->id),
                                issue => $issue,
                                aggregation_series => {
                                                       aggregation_series_uri => $series_uri,
                                                       aggregation_series_name => $series_name,
                                                      },
                               };
    push @{$aggregations{$parent->id}{titles}}, $out{uri};
    if ($issue =~ m/\b((19|20)\d{2})\b/) {
        $out{date} = $1;
    }
    if (my $pubdate = $post->post_date) {
        $out{pubdate} = $pubdate->ymd;
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

print Dumper(\%aggregations);

if ($opts{grandparent}) {
    if (my $title = $opts{'merge-children'}) {
        my $tops = $wp->resultset('WpPost')->published->search({ post_parent => $opts{grandparent} },
                                                               { order_by => ['menu_order'] });
        my @legacy_links;
        while (my $top = $tops->next) {
            print "Done ($title) " . ++$count . "\n";
            my $html = $top->html_body;
            my $issue = $top->post_title || $top->post_name;
            my @lines;
            while ($html =~ m/(<img[^>]+?>)/g) {
                push @lines, $1;
            }
            foreach my $art ($top->children->published->search(undef, {
                                                                       order_by => [qw/menu_order post_name/],
                                                                      })->all) {
                push @lines, sprintf('<p><a href="%s">%s</a></p>', $art->clean_url, $art->post_title);
                my $new_path = "/library/" . muse_naming_algo($top->post_name . '-' . $art->post_name);
                foreach my $legacy_path ($art->clean_url, $art->permalink) {
                    push @legacy_links, {
                                         legacy_path => $legacy_path,
                                         new_path => $new_path,
                                        };
                }
            }

            my %post = (
                        uri => muse_naming_algo($title . '-' . $top->post_name),
                        title => "$series_name $issue",
                        textbody => join("\n\n", @lines),
                        SORTtopics => $title,
                        DELETED => "Not needed",
                       );
            if (my $saved = parse_html(\%post)) {
                my $muse_body = join("\n", grep { /^\[\[[0-9a-z-]+\.(png|jpe?g)\]\]/ } $saved->lines_utf8);
                if ($muse_body) {
                    if ($aggregations{$top->id}) {
                        $aggregations{$top->id}{comment_muse} = $muse_body;
                    }
                    else {
                        print "Missing aggregation for $muse_body ID:" . $top->id . "\n";

                    }
                }
            }
        }
        DumpFile($autoimport_dir->child('legacy_links.yml'), \@legacy_links);
    }
}

my @aggregations;
foreach my $agg (sort { $a->{sorting_pos} <=> $b->{sorting_pos} } grep { defined $_->{issue} } values %aggregations) {
    if ($agg->{issue} =~ m/\A\d+,\s*(.*+)\z/) {
        $agg->{publication_date} = $1;
        if ($agg->{publication_date} =~ m/((19|20)\d{2})/) {
            $agg->{publication_date_year} = $1;
        }
    }
    push @aggregations, $agg;
}
DumpFile($autoimport_dir->child('aggregations.yml'), \@aggregations);

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
        return $final;
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
        if ($opts{'no-image-download'}) {
            return "<div>[[" . $target->basename . "]]</div>";
        }
        my $res = $ua->mirror($src, "$target");
        if ($res->is_success or $res->code eq '304') {
            if ($file =~ m/\A(.+)\.gif\z/i) {
                my $png = $1 . '.png';
                my $destination = $dir->child($img_basename . '-' . $png);
                if (!$destination->exists or $destination->stat->mtime < $target->stat->mtime) {
                    print "Converting $target to $destination\n";
                    system(convert => -strip => "$target", "$destination");
                }
                return "<div>[[" . $destination->basename . "]]</div>"
            }
            print "Downloaded $src\n" if $res->is_success;
            return "<div>[[" . $target->basename . "]]</div>";
        }
        else {
            print "$src => " . $res->status_line . "\n";
        }
    }
    return '';
}
