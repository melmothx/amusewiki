requires 'Catalyst::Runtime' => '5.90075';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Authentication::Realm::SimpleDB';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
requires 'JSON::MaybeXS';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Test::WWW::Mechanize';
requires 'Test::WWW::Mechanize::Catalyst';
requires 'Term::Size::Any';
requires 'Data::Dumper::Concise';
# modules used

# middlewares
requires 'Plack::Middleware::XSendfile';

# needs a recent thing
requires 'MIME::Types' => '2.04';

# for fcgi
requires 'FCGI';
requires 'FCGI::ProcManager';

# for cgit under plack
requires 'CGI::Emulate::PSGI';
requires 'CGI::Compile';

requires 'Config::General'; # Required by Catalyst::Plugin::ConfigLoader
requires 'Unicode::Collate';
requires 'DBIx::Class';
requires 'DBD::SQLite';
requires 'Daemon::Control';
requires 'MooseX::NonMoose';
requires 'DBIx::Class::Schema::Loader';
requires 'SQL::Translator';
requires 'DBIx::Class::InflateColumn::DateTime';
requires 'DBIx::Class::Schema::Config';
requires 'DBIx::Class::Helpers';
requires 'DBIx::Class::InflateColumn::Authen::Passphrase' => '0.03';
requires 'DBIx::Class::PassphraseColumn' => '0.05';
requires 'DBIx::Class::DeploymentHandler';
requires 'DateTime';
requires 'Date::Parse';
requires 'DateTime::Format::SQLite';
requires 'DateTime::Format::MySQL';
requires 'DateTime::Format::Pg';
requires 'DateTime::Format::Strptime';
requires 'XML::FeedPP' => '0.43';
requires 'XML::Atom' => '0.41'; # 2011...
requires 'XML::OPDS' => '0.05';
requires 'Git::Wrapper';
requires 'Text::Wrapper'; # for revision messages
requires 'Email::Valid';
requires 'Regexp::Common';
requires 'File::Copy::Recursive';
requires 'Search::Xapian';
requires 'Catalyst::Model::Adaptor' => '0.10';
requires 'Text::Unidecode' => '1.22'; # version in jessie
requires 'Text::Diff' => 0;
# loggers
requires 'Log::Contextual';
requires 'Log::Log4perl';
requires 'Log::Dispatch';
requires 'Log::Dispatch::File::Stamped';
requires 'Log::Dispatch::FileRotate';
# for the Log::Dispatch::Email::MailSend module
requires 'Mail::Send';
requires 'Email::Sender';
requires 'Email::MIME::Kit' => '3';
requires 'Email::MIME::Kit::Renderer::TT' => '1.001';

requires 'HTTP::Tiny';
requires 'Crypt::XkcdPassword';
requires 'Bytes::Random::Secure';
# let's encrypt
requires 'Crypt::OpenSSL::X509';
requires 'Net::ACME2' => '0.30';

requires 'HTTP::BrowserDetect';
requires 'HTML::Parser';
requires 'HTML::Tree';
requires 'HTML::Packer';
requires 'CSS::Packer';
requires 'JavaScript::Packer';

#images
requires 'Imager';
requires 'PDF::API2';

# our own dogfood
requires 'Text::Amuse' => '1.27';
requires 'PDF::Imposition' => '0.25';
requires 'Text::Amuse::Compile' => '1.31';
requires 'Text::Amuse::Preprocessor' => '0.61';

# devel things to be removed at the end of the development cycle
# requires 'Catalyst::Plugin::StackTrace';
# requires 'Catalyst::Plugin::MemoryUsage';
# requires 'DBIx::Class::Schema::Loader';
requires 'MooseX::MarkAsMethods';
requires 'File::MimeInfo';
requires 'Moo';
requires 'Path::Tiny';
requires 'Locale::Maketext::Lexicon';
requires 'Locale::PO';

test_requires 'Test::More' => '0.88';
test_requires 'CAM::PDF';
test_requires 'Test::Differences';
test_requires 'Test::Warn';
