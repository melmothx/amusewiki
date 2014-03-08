#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

use AmuseWikiFarm::Schema;

my $db = AmuseWikiFarm::Schema->connect('amuse');

ok($db);

my $site = $db->resultset('Site')->find('0test0');

ok($site);

my %formats = $site->available_formats;

is_deeply \%formats, {
                      'bare_html' => 1,
                      'pdf' => 1,
                      'zip' => 1,
                      'html' => 1,
                      'lt_pdf' => 0,
                      'tex' => 1,
                      'a4_pdf' => 0,
                      'epub' => 1
                     };

my %exts = $site->available_text_exts;

is_deeply \%exts, {
                   '.bare.html' => 1,
                   '.pdf' => 1,
                   '.zip' => 1,
                   '.html' => 1,
                   '.lt.pdf' => 0,
                   '.tex' => 1,
                   '.a4.pdf' => 0,
                   '.epub' => 1
                  };






