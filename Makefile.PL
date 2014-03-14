#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'AmuseWikiFarm';
all_from 'lib/AmuseWikiFarm.pm';

requires 'Catalyst::Runtime' => '5.90015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats

# modules used
requires 'Unicode::Collate';
requires 'File::Slurp';
requires 'DBIx::Class::InflateColumn::DateTime';
requires 'DBIx::Class::Schema::Config';
requires 'DBIx::Class::Helper::ResultSet::Random';
requires 'Catalyst::Plugin::I18N';
requires 'DateTime';
requires 'Date::Parse';
requires 'DateTime::Format::SQLite';
requires 'DateTime::Format::MySQL';
requires 'DateTime::Format::Pg';
requires 'XML::FeedPP';


requires 'Search::Xapian';
requires 'Catalyst::Model::Adaptor';

# our own dogfood
requires 'Text::Amuse' => 0.10;
requires 'Text::Amuse::Compile' => 0.07;

# devel things to be removed at the end of the development cycle
# requires 'Catalyst::Plugin::StackTrace';
# requires 'Catalyst::Plugin::MemoryUsage';
# requires 'DBIx::Class::Schema::Loader';
requires 'MooseX::MarkAsMethods';

test_requires 'Test::More' => '0.88';
catalyst_ignore('repo');
catalyst_ignore('xapian');
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
