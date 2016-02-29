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

requires 'Catalyst::Runtime' => '5.90075';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Authentication::Realm::SimpleDB';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::Email::Template';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Test::WWW::Mechanize::Catalyst';
requires 'Term::Size::Any';
# modules used

# middlewares
requires 'Plack::Middleware::ETag';
requires 'Plack::Middleware::ConditionalGET';
requires 'Plack::Middleware::XSendfile';

# needs a recent thing
requires 'MIME::Types' => '2.04';

# for fcgi
requires 'FCGI';
requires 'FCGI::ProcManager';

requires 'Unicode::Collate';
requires 'DBIx::Class';
requires 'DBD::SQLite';
requires 'Daemon::Control';
requires 'MooseX::NonMoose';
requires 'JSON';
requires 'JSON::XS';
requires 'DBIx::Class::Schema::Loader';
requires 'SQL::Translator';
requires 'DBIx::Class::InflateColumn::DateTime';
requires 'DBIx::Class::Schema::Config';
requires 'DBIx::Class::Helper::ResultSet::Random';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::DeploymentHandler';
requires 'Catalyst::Plugin::I18N';
requires 'DateTime';
requires 'Date::Parse';
requires 'DateTime::Format::SQLite';
requires 'DateTime::Format::MySQL';
requires 'DateTime::Format::Pg';
requires 'XML::FeedPP' => '0.43';
requires 'XML::Atom' => '0.41'; # 2011...
requires 'Git::Wrapper';
requires 'Text::Wrapper'; # for revision messages
requires 'Email::Valid';
requires 'File::Copy::Recursive';
requires 'Search::Xapian';
requires 'Catalyst::Model::Adaptor' => '0.10';
requires 'Text::Unidecode' => '1.22'; # version in jessie
# loggers
requires 'Log::Contextual';
requires 'Log::Log4perl';
requires 'Log::Dispatch';
requires 'Log::Dispatch::File::Stamped';
# for the Log::Dispatch::Email::MailSend module
requires 'Mail::Send';

requires 'HTTP::Tiny';
requires 'Crypt::XkcdPassword';

# our own dogfood
requires 'Text::Amuse' => '0.54';
requires 'PDF::Imposition' => '0.21';
requires 'Text::Amuse::Compile' => '0.55';
requires 'Text::Amuse::Preprocessor' => '0.25';

# devel things to be removed at the end of the development cycle
# requires 'Catalyst::Plugin::StackTrace';
# requires 'Catalyst::Plugin::MemoryUsage';
# requires 'DBIx::Class::Schema::Loader';
requires 'MooseX::MarkAsMethods';
requires 'File::MimeInfo';

test_requires 'Test::More' => '0.88';
test_requires 'CAM::PDF';
test_requires 'Test::Differences';

# locations where we store the stuff
catalyst_ignore('repo',
                'xapian',
                'staging',
                'opt',
                'bbfiles',
                'var',
                'design',
                'bootstrap-amw',
                'current_version_is_.*txt',
                'dbic.yaml',
                'log',
                'cronjobs',
                '.*local\.conf',
                'ext-src',
                'thumbnails',
                'webfonts',
                'doc',
                'init-.*',
                '.*\.txt',
                '\.git.*',
                'MANIFEST.*',
                'Makefile.*',
                '.*\.db',
                '.*\.db-journal',
                'AmuseWikiFarm.*',
                'stock_files',
                'font-preview',
                'db_backups',
                '.*\.lock',
                '.*\.example',
                'ssl');
catalyst;

install_script glob('script/amusewiki-*');
auto_install;
WriteAll;
