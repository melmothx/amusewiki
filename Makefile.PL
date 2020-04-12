#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'AmuseWikiFarm';
license 'perl';
all_from 'lib/AmuseWikiFarm.pm';

do './cpanfile';

# locations where we store the stuff
catalyst_ignore('repo',
                'shared',
                'xapian',
                'staging',
                'opt',
                'bbfiles',
                'var',
                'design',
                'bootstrap-amw',
                'current_version_is_.*txt',
                'dbic.yaml',
                'cover_db',
                'log',
                'cronjobs',
                '.*local\.conf',
                'ext-src',
                'thumbnails',
                'webfonts',
                'doc',
                'init-.*',
                'upgrade-from-git\.sh',
                '.*\.txt',
                '\.git.*',
                'Maildir',
                'MANIFEST.*',
                'LICENSE',
                'Makefile.*',
                '.*\.db',
                '.*\.db-journal',
                '*.aux',
                '*.toc',
                'AmuseWikiFarm.*',
                'stock_files',
                'font-preview',
                'db_backups',
                '.*\.lock',
                '.*\.example',
                'fontspec.json',
                'ssl',
                'CONTRIBUTING.md',
                'MYMETA.json',
                'MYMETA.yml',
                'README.mdwn',
                'Vagrantfile');
catalyst;

install_script glob('script/amusewiki-*');
auto_install;
WriteAll;
