#!/usr/bin/env perl

# test which always passes, but which has the site effect to bootstrap
# the archives needed for the tests. TODO Activate this properly
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use File::Copy qw/copy/;
use DBIx::Class::DeploymentHandler;
use Text::Amuse::Compile::Utils qw/read_file write_file/;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBICDH_DEBUG} = 1;
};

use AmuseWikiFarm::Schema;

diag "Using DBIC $DBIx::Class::VERSION\n";

plan tests => 20;

system('script/amusewiki-populate-webfonts') == 0 or die;

unless (-d catdir(qw/root static images font-preview/)) {
    system('font-preview/gen.sh') == 0 or die "Couldn't generate the font preview";
}

my $texmfhome = `kpsewhich -var-value TEXMFHOME`;
chomp $texmfhome;
my $texmffiledir = catdir($texmfhome, qw/tex generic amusewiki data/);

foreach my $pdflogo (qw/logo-yu.pdf logo-en.pdf/) {
    unless (system(kpsewhich => $pdflogo) == 0) {
        diag "$pdflogo not found, installing it into into $texmffiledir";
        make_path($texmffiledir, { verbose => 1 }) unless -d $texmffiledir;
        my $src = catfile(qw/t texmf-files/, $pdflogo);
        copy($src, $texmffiledir)
          or die "Failed to copy $src into $texmffiledir $!";
        system(texhash => $texmfhome);
        unless (system(kpsewhich => $pdflogo) == 0) {
            die "Couldn't find or install $pdflogo into TEXMFHOME, please report this issue\n";
        }
    }
}

if (-f 'test.db') {
    unlink 'test.db' or die $!;
}

{
    my $schema = AmuseWikiFarm::Schema->connect('amuse');
    if ($schema->storage->sqlt_type eq 'SQLite') {
        $schema->storage->dbh->do('pragma foreign_keys=off');
    }
    my $dh = DBIx::Class::DeploymentHandler->new({
                                                  schema => $schema,
                                                  databases => [qw/SQLite MySQL PostgreSQL/],
                                                  sql_translator_args => { add_drop_table => 0,
                                                                           quote_identifiers => 1,
                                                                         },
                                                  script_directory => "dbicdh",
                                                 });
    $dh->install({ version => 2 });
    $dh->upgrade;
    unlink 'test.db' or die $!;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');

DBIx::Class::DeploymentHandler->new({
                                     schema => $schema,
                                     databases => [qw/SQLite MySQL PostgreSQL/],
                                     sql_translator_args => { add_drop_table => 0,
                                                              quote_identifiers => 1,
                                                            },
                                     script_directory => "dbicdh",
                                    })->install;

ok (-f 'test.db', "test.db created");
ok($schema, "Schema exists now");

# we create two repos, 0blog0 and 0test0

# create the root user

my $mr_root = $schema->resultset('User')
  ->create({
            username => 'root',
            password => 'root',
            email => 'root@amusewiki.org',
           })->discard_changes;

my $root_role = $schema->resultset('Role')->create({ role => 'root' });
my $libr_role = $schema->resultset('Role')->create({ role => 'librarian' });

$mr_root->add_to_roles($root_role);

ok($mr_root->id);


my %repos = ('0blog0' => {
                          id => '0blog0',
                          locale => 'hr',
                          mode => 'modwiki',
                          sitename => 'A moderated wiki',
                          siteslogan => 'samo test',
                          bb_page_limit => 10,
                          logo => 'logo-yu',
                          a4_pdf => 0,
                          lt_pdf => 0,
                          papersize => 'a4',
                          division => '9',
                          bcor => '1cm',
                          fontsize => 12,
                          mainfont => 'Linux Libertine O',
                          twoside => 1,
                          canonical => 'blog.amusewiki.org',
                          secure_site => 0,
                          site_options => [{
                                            option_name => 'paginate_archive_after',
                                            option_value => 1,
                                           },
                                           {
                                            option_name => 'use_js_highlight',
                                            option_value => 'perl bash',
                                           },
                                          ],
                         },
             '0test0' => {
                          id => '0test0',
                          locale => 'en',
                          mode => 'blog',
                          sitename => 'A test blog',
                          siteslogan => 'only a test',
                          theme => 'amusejournal',
                          bb_page_limit => 20,
                          logo => 'logo-en',
                          a4_pdf => 0,
                          pdf => 1,
                          lt_pdf => 0,
                          papersize => '',
                          division => '12',
                          bcor => '0mm',
                          fontsize => 10,
                          twoside => 1,
                          canonical => 'test.amusewiki.org',
                         },
            );

foreach my $repo (sort keys %repos) {
    my $src = catdir(qw/t test-repos/, $repo);
    my $dest = catdir('repo', $repo);
    if (-d $dest) {
        remove_tree($dest) or die $!;
    }
    ok(dircopy($src, $dest), "File copied, ready to go");
    my $site = $schema->resultset('Site')->create($repos{$repo})->discard_changes;
    ok ($site->id) or diag $repo->{id} . " couldn't be created";
    $site->magic_question('First month of the year');
    $site->magic_answer('January');
    $site->sitegroup('1');
    $site->update;
    $site->update_db_from_tree(sub { diag join(' ', @_) });
    if (my $mainfont = $repos{$repo}{mainfont}) {
        foreach my $text ($site->titles->published_texts) {
            my $html = read_file($text->filepath_for_ext('html'));
            like $html, qr{\Q$mainfont\E};
        }
    }
    ok -d $site->root_install_directory;
    diag "INSTALL DIRECTORY is " . $site->root_install_directory;
    ok -d $site->mkits_location;
    ok -d $site->templates_location;
}

my $blog = $schema->resultset('Site')->find('0blog0');

my @others = $blog->other_sites;

is scalar(@others), 1, "Found the other site";


foreach my $i (1..3) {
    my $user = $schema->resultset('User')
      ->create({
                username => "user" . $i,
                password => "pass",
               })->discard_changes;
    if ($i == 3) {
        $user->active(0);
        $user->update;
    }
    $user->add_to_roles($libr_role);
    $user->add_to_sites($blog);
    ok($user->id, "Found " . $user->id);
}

$schema->resultset('User')->create({ username => 'marcomarco',
                                     password => 'marcomarco',
                                     user_roles => [ { role => { role => 'admin' } } ] })
  ->add_to_sites($blog);

