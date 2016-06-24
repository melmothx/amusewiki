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
use LWP::UserAgent;
use File::Spec;
binmode STDOUT, ':encoding(UTF-8)';

my $ua = LWP::UserAgent->new;
my ($site_id, $file, $hostname) = @ARGV;
die unless $site_id && $file;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find($site_id) or die "cannot find site $site_id";
my $import_id = 1;
my $wd = File::Temp->newdir;
$site->update({ pdf => 0 });

my $feeder = XML::RSS::LibXML->new;
$feeder->parsefile($file);
my $language = $feeder->{channel}->{language};
die "No language found" unless $language;

$site->legacy_links->delete;
my @feeds = $feeder->items;
POST:
foreach my $entry (@feeds) {
    my $meta = $entry->{wp};
    if ($meta and $meta->{post_type} and $meta->{post_type} eq 'post') {
        my %out;
        $out{lang} = $language;
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

        # garbage anyway at this pont
        $out{body} =~ s!</?(center|right)>!!g;
        if ($out{body} =~ m{\A
                            \s*
                            \[\[
                            (https?://\Q$hostname\E/[^\]]*?)
                            \]\]
                            \s*
                            (.*)
                            \z}sx) {
            $out{cover} = $1;
            $out{body} = $2;
        }
        unless ($out{teaser}) {
            $out{teaser} = $out{body};
            if (length($out{teaser}) > 800) {
                $out{teaser} = substr $out{teaser}, 0, 2000;
                $out{teaser} =~ s/\n\n[^\n]+\z//;
            }
            $out{teaser} =~ s/\n\n/ <br> /g;
            $out{teaser} .= '...';
        }
        $out{title} = $entry->{title};
        if (my $categories = $entry->{category}) {
            my @cats;
            if (ref($categories) eq 'ARRAY') {
                foreach my $cat (@$categories) {
                    push @cats, "$cat";
                }
            }
            else {
                push @cats, "$categories";
            }
            if (@cats) {
                $out{topics} = join('; ', @cats);
            }
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
    $string =~ s!</?(quote|center|right)>!!g;
    return $string;
}

sub add_text {
    my $text = shift;
    die unless $text;
    my ($revision) = $site->create_new_text({
                                             title => $text->{title},
                                             uri => "wp-" . $import_id++ . "-vx7",
                                             textbody => $text->{html},
                                            }, 'text');
    if (my $cover = $text->{cover}) {
        my $target = File::Spec->catfile($wd, 'out.png');
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
    my @body;
    my $muse = $text->{body};
    my @pdfs;
    $muse =~ s!
           \[\[
           (https?://\Q$hostname\E/[^\]]*?\.(pdf|png|jpe?g))\]
           (\[.*?\])?
           \]!attach_to_text($revision, $1, $3, \@pdfs)!gex;

    foreach my $f (qw/title pubdate topics teaser cover lang/) {
        if (my $v = clean_inline($text->{$f})) {
            push @body, "#$f $v";
        }
    }
    if (@pdfs) {
        push @body, "#ATTACH " . join(' ', @pdfs);
    }
    push @body, "\n", $muse, "\n";
    $revision->edit(join("\n", @body));
    $revision->commit_version;
    my $new_uri = $revision->publish_text;
    print "New uri is $new_uri\n";
    foreach my $old (@{$text->{legacy_links}}) {
        $site->add_to_legacy_links({
                                    legacy_path => $old,
                                    new_path => $new_uri,
                                   });
    }
}

sub attach_to_text {
    my ($rev, $url, $desc, $pdfs) = @_;
    $desc ||= '';
    die unless $rev && $url;
    print "Replacing $url $desc\n";
    my $tmp = File::Temp->newdir;
    my $local = File::Spec->catfile($tmp, 'downloaded');
    $ua->mirror($url, $local);
    unless (-f $local) {
        warn "FAILED to download $url";
        return $desc;
    }
    my $got = $rev->add_attachment($local);
    if ($got->{error}) {
        print Dumper($got);
        warn "FAILED to add $local file";
        return $desc;
    }
    die unless $got->{attachment};
    if ($got->{attachment} =~ m/\.pdf$/) {
        push @$pdfs, $got->{attachment};
        $got->{attachment} = '#amw-attached-pdfs';
    }
    return "\n\n[[" . $got->{attachment} . "]$desc]\n\n";
}
