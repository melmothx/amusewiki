#!/usr/bin/env perl

BEGIN {
    $ENV{DBICDH_DEBUG} = 1;
}
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DBIx::Class::DeploymentHandler;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Try::Tiny;
use Cwd;
use Getopt::Long;
use Crypt::XkcdPassword;

my $hostname;
my $site_id = 'amw';
my $password = Crypt::XkcdPassword->new(words => 'IT')->make_password(5, qr{\A[0-9a-zA-Z]{3,}\z});
my $username = "amusewiki";

GetOptions(
           'hostname=s' => \$hostname,
           'username=s' => \$username,
           'password=s' => \$password,
          ) or die;

unless ($hostname) {
   $hostname = `hostname -d` || 'localdomain';
   chomp $hostname;
   $hostname = 'amusewiki.' . $hostname;
}


# load the db

my $schema = AmuseWikiFarm::Schema->connect('amuse');

die "Couldn't load the schema! Please check dbic.yaml!\n" unless $schema->storage->dbh;

my $dh = DBIx::Class::DeploymentHandler->new({
                                              schema => $schema,
                                              databases => [qw/SQLite MySQL PostgreSQL/],
                                              sql_translator_args => {
                                                                      add_drop_table => 0,
                                                                      quote_identifiers => 1,
                                                                     },
                                              script_directory => "$FindBin::Bin/../dbicdh",
                                             });

$dh->install;

if (my @sites = $schema->resultset('Site')->all) {
    die "There are already sites in this database, aborting\n";
}

if (my @users = $schema->resultset('User')->all) {
    die "There are already user in this database, aborting\n";
}

if ($hostname =~ m/^\s*([a-z0-9-]+(\.[a-z0-9-]+)*)\s*$/) {
    $hostname = $1;
}
else {
    die "Host name $hostname doesn't look valid\n";
}
if ($site_id =~ m/\A\s*([1-9a-z][0-9a-z]{1,15})\s*\z/) {
    $site_id = $1;
}
else {
    die "Site code contains illegal characters\n";
}

if ($username =~ m/\s*([a-z0-9]+)\s*/) {
    $username = $1;
}
else {
    die qq{Bad username "$username"\n};
}

unless ($password =~ m/\A[[:ascii:]]+\z/) {
    die qq{Bad password, non ascii\n};
}

my $site = $schema->resultset('Site')->create({
                                               id => $site_id,
                                               canonical => $hostname,
                                               sitename => "AmuseWiki documentation",
                                               pdf => 0, # no pdfs for this, speed up
                                              });
$site->discard_changes;
my $repo_root = $site->repo_root;

unless (-d $repo_root) {
    if (system(git => clone => "git://amusewiki.org/git/amw.git" => $site->repo_root) == 0) {
        print "Repository with the official documentation has been created at " . $site->repo_root . "\n";
    }
    elsif ($site->initialize_git) {
        print "An stub repository has been created at " . $site->repo_root . "\n";
    }
    else {
        die "This shouldn't happen";
    }
}
# compile
$site->update_db_from_tree(sub { });

my $user = $schema->resultset('User')->create({
                                               username => $username,
                                               password => $password,
                                              });
$user->set_roles([{ role => 'root' }]);

print <<"EOF";
Summary of the initial setup:

Host: "$hostname"
Site ID: "$site_id"
Root username: "$username"
Root password: "$password"

You should be able to login at http://$hostname/login with the above
credentials.

EOF
