package AmuseWikiFarm::Archive::CgitProxy;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use URI;
use HTTP::Tiny;
use AmuseWikiFarm::Archive::CgitProxy::Response;

has port => (is => 'ro',
             isa => 'Int',
             default => '9015',
            );

has host => (is => 'ro',
                 isa => 'Str',
                 default => sub { 'localhost' });

has scheme => (is => 'ro',
               isa => 'Str',
               default => sub { 'http' });

has base_path => (is => 'ro',
                  isa => 'Str',
                  default => sub { 'git' });

has ua => (is => 'ro',
           isa => 'Object',
           default => sub { HTTP::Tiny->new });

has disabled => (is => 'ro',
                 isa => 'Bool',
                 lazy => 1,
                 builder => '_build_disabled');

sub _build_disabled {
    my $self = shift;
    my $test_uri = $self->create_uri;
    my $res = $self->ua->get($test_uri);
    return !$res->{success};
}

sub get_base_uri {
    my $self = shift;
    my $uri = $self->scheme . '://' . $self->host .
      ($self->port ? ':' . $self->port : '');
    return URI->new($uri);
}

sub create_uri {
    my ($self, $args, $params) = @_;
    $args ||= [];
    $params ||= {};
    unless (ref($args) and ref($args) eq 'ARRAY') {
        die "first argument must be an arrayref";
    }
    unless (ref($params) and ref($params) eq 'HASH') {
        die "second argument (params) must be a hashref";
    }
    my $uri = $self->get_base_uri;
    my @path = ($self->base_path, @$args);
    $uri->path(join('/', @path));
    $uri->query_form($params) if %$params;
    return $uri->as_string;
}

sub get {
    my ($self, $args, $parms) = @_;
    my $uri = $self->create_uri($args, $parms);
    my $res =
      AmuseWikiFarm::Archive::CgitProxy::Response->new($self->ua->get($uri));
    unless ($res->success) {
        warn join(" ", $res->url, $res->status, $res->reason);
    }
    return $res;
}

__PACKAGE__->meta->make_immutable;

1;
