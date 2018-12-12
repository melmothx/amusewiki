package AmuseWikiFarm::Archive::CgitEmulated;

use utf8;
use strict;
use warnings;
use Moo;
use HTTP::Message;
use IPC::Run qw/run timeout/;
use AmuseWikiFarm::Utils::CgitSetup;
use AmuseWikiFarm::Log::Contextual;
use File::Spec;

has cgit => (is => 'lazy');

sub _build_cgit {
    # prefer system-wide locations
    my @locations = (
                     '/usr/lib/cgit/cgit.cgi',
                     '/var/www/cgi-bin/cgit', # centos
                     '/usr/local/www/cgit/cgit.cgi', # freebsd
                     File::Spec->rel2abs('root/git/cgit.cgi'), # installed by us
                    );
    my $cgit_exec;
    foreach my $cgit (@locations) {
        if (-f $cgit) {
            $cgit_exec = $cgit;
            # log_debug { "Using $cgit as cgit executable" };
            last;
        }
    }
    return $cgit_exec;
}

has rcfile => (is => 'ro',
               default => sub { AmuseWikiFarm::Utils::CgitSetup->new->cgitrc });

sub enabled {
    my $self = shift;
    if ($self->rcfile && $self->rcfile) {
        return 1;
    }
    else {
        return 0;
    }
}

sub get {
    my ($self, $args, $params, $env) = @_;
    my $uri = URI->new;
    $uri->path('/' . join('/', @{ $args || []}));
    $uri->query_form({ %{ $params || {} } });
    log_debug { "Getting $uri " };
    my ($out, $err);
    my %req_headers = map { $_ => $env->{$_} } grep { /^(HTTP_|REQUEST_)/ } keys %{ $env || {} };
    delete $req_headers{HTTP_PROXY};
    {
        local %ENV = (
                      %req_headers,
                      CGIT_CONFIG => $self->rcfile,
                      SCRIPT_NAME => '/git',
                      PATH_INFO => $uri->path,
                      QUERY_STRING => $uri->query,
                      SERVER_NAME => 'localhost',
                      SERVER_PORT => 80,
                      SERVER_PROTOCOL => 'HTTP/1.1',
                      GATEWAY_INTERFACE => 'CGI/1.1',
                      HTTPS => 'OFF',
                      SERVER_SOFTWARE => "AmuseWikiFarm::Archive::CgitEmulated",
                      REMOTE_ADDR     => '127.0.0.1',
                      REMOTE_HOST     => 'localhost',
                      REMOTE_PORT     => int( rand(64000) + 1000 )
                     );
        # Dlog_debug { "Environment is $_" } \%ENV;
        my $in;
        run [ $self->cgit ], \$in, \$out, \$err, timeout(6) or die;
    };
    if ($err) {
        Dlog_error { "$err with $_" } [ $args, $params ];
    }
    # Dlog_debug { "Environment is $_" } \%ENV;
    my $res = HTTP::Message->parse($out);
    # Dlog_debug { "Res is $_" } $res;
    return $res;
}


1;
