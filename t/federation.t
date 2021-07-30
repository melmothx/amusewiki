#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 15;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_1 = create_site($schema, '0federation0');
my $site_2 = create_site($schema, '0federation1');

__END__


* Origin:

 - store checksums for indexed files
 - provide manifest.json with URLs and checksums to various access points
   like /listing /category/x/y/manifest.json

* Client:

 - has a list of URLs to mirror.
 - retrieves the manifest
 - exclude exceptions
 - checks the netto list. Use a timestamp as reference
    - already mirrored? compare the checksums. 
       - If different? Fetch the resource.
       - Update the mirroring timestamp

    - new file? Fetch the resource and add the mirroring info,
      including the mirroring timestamp.

    - check files having that resource as origin and a timestamp which
      is not the same. Remove them.

* Interface:

 - you can add one or more origins
 - each origin can have exceptions
 - when adding exceptions, define a behavior. Remove files? Unlink
   them?
 - when removing origins, define a behavior. Remove files? Unlink
   them?


* Schema

Each site can have one or more mirror_origin. It defines a domain and
a path where to fetch the manifests.

Each text and attachment has a mirror_info record attached. With
mirror_origin_id null, it's a regular, local file. It still carries
the md5sum. We point to this record for exclusions and conflicts.

mirror_exclusion can be "exclusion" or "conflict".




