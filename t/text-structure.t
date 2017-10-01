#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');


my $testnotoc =<<'MUSE';
#lang en
#title helloooo <&!"'title>

Hello

MUSE

my $testnotocwithfinal =<<'MUSE';
#lang en
#title helloooo <&!"'title>
#notes This is a not

Hello

MUSE


my $test_no_intro =<<'MUSE';
#lang en
#title Hullllooooo <&!"'title>

*** subsection

* Part

** Chap 1

** Chap 2

**** Subsection
MUSE

my $testbody =<<'MUSE';
#title hello world <&!"'title>

Hello world!

**** Intro

Introduction

* Part 1

**** subsection before chapter

** Chapter *1*

Chapter body

*** Section *1.1*

Section body

*** Section **1.2**

Section body

** Chapter *2*

Chapter body

**** subsection of chapter 2

*** Section **2.1**

Section body

**** Subsection 2.1.1 & test

Subsection body

**** Subsection 2.1.1

Subsection body 2

** Chapter 3

Section 

**** Subsection 3.0.1 [1]

Subsection

[1] example

Subsection

***** Subsubsection

Subsub section

* Part 2

Part again

*** Section of second part

** Chapter of second part

**** Subsection of chap 1 of part 2.

* Part 3

**** Subsection of part 3

** Chapter 1 of part 3

**** Subsection of part 3, chap 1

** Chapter 2 of part 3

** Chapter 3 of part 3

MUSE

my @tests = (
             {
              body => $testnotoc,
              name => 'notoc',
             },
             {
              body => $testnotocwithfinal,
              name => 'notoc-finalpage',
             },
             {
              body => $test_no_intro,
              name => 'nointro',
             },
             {
              body => $testbody,
              name => 'full',
             }
            );

my $site = create_site($schema, '0textstruct0');
$site->update({ secure_site => 0,
                pdf => 0,
                epub => 0,
                html => 1,
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


foreach my $muse (@tests) {
    my ($rev) = $site->create_new_text({ title => $muse->{name} }, 'text');
    $rev->edit($muse->{body});
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    $mech->get_ok($title->full_uri);
    diag Dumper($title->_retrieve_text_structure);
}
