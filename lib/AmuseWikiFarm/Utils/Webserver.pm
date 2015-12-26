package AmuseWikiFarm::Utils::Webserver;

use strict;
use warnings;
use Moose;
use namespace::autoclean;

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::CgitProxy;

has cgit_port => (is => 'ro',
                  isa => 'Int',
                  default => sub { '9015' },
                 );

has log_format => (is => 'ro',
                   isa => 'Str',
                   default => sub { 'combined' });

has nginx_root => (is => 'ro',
                   isa => 'Str',
                   default => sub { '/etc/nginx' });

has instance_name => (is => 'ro',
                      isa => 'Str',
                      default => sub { 'amusewiki' });

has fcgiwrap_socket => (is => 'ro',
                        isa => 'Str',
                        default => sub { '/var/run/fcgiwrap.socket' });

has cgit_proxy => (is => 'ro',
                   isa => 'Object',
                   lazy => 1,
                   builder => '_build_cgit_proxy');

sub _build_cgit_proxy {
    my $self = shift;
    log_info { "Loading cgitproxy" };
    return AmuseWikiFarm::Archive::CgitProxy->new(port => $self->cgit_port);
}

__PACKAGE__->meta->make_immutable;


1;
