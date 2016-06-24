#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 'lib';
use URI;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Date::Parse;
$Data::Dumper::Sortkeys =1;
use XML::RSS::LibXML;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
use File::Temp;
use File::Spec;
binmode STDOUT, ':encoding(UTF-8)';

my ($site_id, $file, $hostname) = @ARGV;
die unless $site_id && $file;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find($site_id) or die "cannot find site $site_id";
my $import_id = 1;
my $wd = File::Temp->newdir;

my $feeder = XML::RSS::LibXML->new;
$feeder->parsefile($file);
my @feeds = $feeder->items;
POST:
foreach my $entry (@feeds) {
    my $meta = $entry->{wp};
    if ($meta and $meta->{post_type} and $meta->{post_type} eq 'post') {
        my %out;
        my $body = $entry->{content}->{encoded};
        next POST unless $body;
        $out{html} = $body;
        my $date = $entry->{pubDate};
        if ($date =~ m{\w -0001 \d}) {
            print "Ignoring post with date $date";
            next POST;
        }
        else {
            $out{pubdate} = $date;
        }
        $body =~ s/\r?\n/<p \/>/g;
        my @links;
        foreach my $name (qw/link guid/) {
            if (my $v = $entry->{$name}) {
                my $uri = URI->new("$v");
                push @links, $uri->path_query;
            }
        }
        $out{legacy_links} = \@links;
        if ($body =~  m{\A\s*<a .*?>.*?</a>(.*?)<!--\s*more\s*-->}si) {
            my $teaser = $1;
            my $muse_teaser = wp_html_to_muse($teaser);
            $muse_teaser =~ s/\n\n/ <br> /g;
            $out{teaser} = $muse_teaser;
        }
        else {
        }
        $out{body} = wp_html_to_muse($body);
        next POST unless $out{body};
        $out{body} =~ s!<center>\s*</center>!!gs;
        if ($out{body} =~ m{\A
                            \s*
                            (?:<center>\s*)?
                            \[\[
                            (https?://\Q$hostname\E/[^\]]*?)
                            \]\]
                            (?:\s*</center>)?
                            \s*
                            (.*)
                            \z}sx) {
            $out{cover} = $1;
            $out{body} = $2;
        }
        $out{teaser} ||= $out{body};
        $out{teaser} = clean_inline($out{teaser});
        $out{title} = clean_inline($entry->{title});
        if (my $topics = clean_inline(join '; ', @{$entry->{category}})) {
            $out{topics} = $topics;
        }
        # download, resize, convert, purify, all in one
        # system covert -resize 300x300 $out{cover} out.png
        add_text(\%out);
    }
}

sub wp_html_to_muse {
    my $body = shift;
    return unless $body;
    my $muse = html_to_muse($body);
    # because for someone HTML is like alcohol for the Indians.
    $muse =~ s/\s+\]\]/]]/sg;
    $muse =~ s/\]\[\]\]/]]/sg;
    $muse =~ s/\s*\z//;
    return $muse;
}

sub clean_inline {
    my $string = shift;
    return '' unless defined $string;
    $string =~ s/\s+/ /g;
    $string =~ s!</?(center|right)>!!;
    return $string;
}

sub add_text {
    my $text = shift;
    die unless $text;
    my ($revision) = $site->create_new_text({
                                             title => $text->{title},
                                             uri => "wp-" . $import_id++ . "x",
                                             textbody => $text->{html},
                                            }, 'text');
    if (my $cover = $text->{cover}) {
        my $target = File::Spec->catfile($wd, 'out.png');
        if (system(convert => -resize => '300x300', $cover, $target) == 0) {
            $revision->add_attachment($target);
            $text->{cover} = ${$revision->attached_files}[0];
        }
        else {
            warn "Fetching $cover failed!";
            delete $text->{cover};
        }
    }
    my @body;
    foreach my $f (qw/title pubdate topics teaser cover/) {
        if (my $v = clean_inline($text->{$f})) {
            push @body, "#$f $v";
        }
    }
    push @body, "\n", $text->{body}, "\n";
    $revision->edit(join("\n", @body));
    $revision->commit_version;
    my $new_uri = $revision->publish_text;
    print "New uri is $new_uri\n";
}
