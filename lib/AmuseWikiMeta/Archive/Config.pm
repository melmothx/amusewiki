package AmuseWikiMeta::Archive::Config;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str HashRef ArrayRef Object/;
use URI;
use YAML;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse;
use Path::Tiny;
use HTML::Entities qw/encode_entities/;

has config_file => (is => 'ro', isa => Str, required  => 1);
has schema => (is => 'ro', isa => Object);
has config => (is => 'lazy', isa => HashRef);

has root_directory => (is => 'lazy', isa => Str);
has stub_database => (is => 'lazy', isa => Str);
has site_list => (is => 'lazy', isa => ArrayRef);

has site_map => (is => 'lazy', isa => HashRef);
has languages_map => (is => 'lazy', isa => HashRef);
has hostnames_map => (is => 'lazy', isa => HashRef);


sub _build_config {
    my $self = shift;
    my $hashref = YAML::LoadFile($self->config_file);
    Dlog_debug { "Loading config file $_" } $hashref;
    return $hashref;
}

sub _build_stub_database {
    my $self = shift;
    my $db = path($ENV{AMW_META_XAPIAN_DB} || ($self->root_directory, "xapian.stub"))->absolute;
    die "No stub_database key found in config file and no AMW_META_XAPIAN_DB set" unless $db;
    $self->generate_xapian_stub_db($db) unless -f $db;
    die "$db is not a file" unless -f $db;
    log_debug { "stub db is $db" };
    return "$db";
}

sub _build_site_list {
    my $self = shift;
    log_debug { "Loading site map" };
    # will die if not an arrayref
    return $self->config->{sites};
}

sub _build_root_directory {
    my $self = shift;
    my $root = $ENV{AMW_META_ROOT} || $self->config->{root_directory};
    die "No root_directory key found in config and AMW_META_ROOT not set" unless $root;
    die "$root is not a directory" unless -d $root;
    log_debug { "root is $root" };
    return $root;
}

sub _build_languages_map {
    return AmuseWikiFarm::Utils::Amuse::known_langs();
}

sub _build_site_map {
    my $self = shift;
    my $site_map = { map { $_->{id} => $_->{canonical_url} } @{$self->site_list} };
    Dlog_debug { "Site map is $_" } $site_map;
    return $site_map;
}

sub _build_hostnames_map {
    my $self = shift;
    my $hostname_map = { map { URI->new($_->{canonical_url})->host => $_->{sitename} }  @{$self->site_list} };
    Dlog_debug { "Hostname map is $_" } $hostname_map;
    return $hostname_map;
}

sub generate_config {
    my $self = shift;
    YAML::DumpFile($self->config_file,
                   {
                    sites => [  map { +{
                                        id => $_->id,
                                        canonical_url => $_->canonical_url,
                                        sitename => $_->sitename,
                                        xapian => path($_->xapian->xapian_dir)->absolute->stringify,
                                        languages => [ $_->supported_locales ],
                                       }
                                  } $self->schema->resultset('Site')->public_only->all
                             ],
                    meta => {
                             name => 'Site Name',
                             description => 'Site Description',
                             adult_content => 0,
                             icon_url => 'https://amusewiki.org/favicon.ico',
                             is_private => 0,
                            },
                   });
}

sub generate_xapian_stub_db {
    my ($self, $file) = @_;
    $file->spew(map { "auto " . $_->{xapian} . "\n" } grep { -d $_->{xapian} } @{$self->site_list});
    Dlog_info { "Generated $file with content: " . $file->slurp };
}

sub meta_info {
    my $self = shift;
    my %meta = %{ $self->config->{meta} || {} };
    foreach my $k (qw/name description/) {
        $meta{$k} = '' unless defined $meta{$k};
        $meta{$k} = encode_entities($meta{$k}, q{<>&"'});
    }
    my @all_langs = map { @{ $_->{languages} } } @{ $self->site_list };
    my %langs;
    foreach my $l (@all_langs) {
        $langs{$l}++ if $l =~ m/\A[a-z]{2}\z/a;
    }
    $meta{languages} = [ sort keys %langs ];
    return \%meta;
}

1;
