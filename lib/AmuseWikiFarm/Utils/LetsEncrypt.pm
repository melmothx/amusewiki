package AmuseWikiFarm::Utils::LetsEncrypt;

# logic blatantly stolen from https://github.com/oetiker/AcmeFetch

use Moo;
use Types::Standard qw/Bool ArrayRef Str Object/;
use Path::Tiny;
use Protocol::ACME;
use Protocol::ACME::Challenge::LocalFile;
use Crypt::OpenSSL::X509;
use DateTime;
use Try::Tiny;

has staging => (is => 'ro', isa => Bool, default => 1);

has directory => (is => 'ro', isa => Str, required => 1);

has root => (is => 'ro', isa => Str, required => 1);

has account_key => (is => 'lazy', isa => Str);

has cert_key => (is => 'lazy', isa => Str);

has names => (is => 'ro', isa => ArrayRef[Str], required => 1);

has mailto => (is => 'ro', isa => Str, required => 1);

sub _build_account_key {
    my $self = shift;
    my $file = path($self->directory, 'account_key.pem');
    unless (-f $file) {
        system(openssl => genrsa => -out => "$file", "2048") == 0
          or die "Cannot create $file!";
        chmod 0600, $file;
    }
    return "$file";
}

sub _build_cert_key {
    my $self = shift;
    my $file = path($self->directory, 'key.pem');
    return "$file";
}

has cert_key_temp => (is => 'lazy', isa => Str);

has certificate_temp => (is => 'lazy', isa => Str);

has certificate => (is => 'lazy', isa => Str);

has now_string => (is => 'ro', default => sub { my $now = DateTime->now;
                                                return '.' . $now->ymd . '-' . $now->epoch });

sub _build_certificate {
    my $self = shift;
    my $file = path($self->directory, 'csr.pem');
    return "$file";
}

sub _build_certificate_temp {
    my $self = shift;
    return $self->certificate . $self->now_string;
}

sub _build_cert_key_temp {
    my $self = shift;
    return $self->cert_key . $self->now_string;
}

has host => (is => 'lazy', isa => Str);

sub _build_host {
    my $self = shift;
    if ($self->staging) {
        return 'acme-staging.api.letsencrypt.org';
    }
    else {
        return 'acme-v01.api.letsencrypt.org';
    }
}


sub _gen_key {
    my ($self, $file) = @_;
}

sub make_csr {
    my $self = shift;
    my $config = Path::Tiny->tempfile(SUFFIX => '.cfg');
    $config->spew($self->_openssl_config_body);
    system (qw(openssl req -nodes -newkey rsa:2048 -batch -reqexts SAN -outform PEM
               -keyform PEM),
            -keyout => $self->cert_key_temp,
            -out  => $self->certificate_temp,
            -config => "$config") == 0 or die "Failed to create cert";
    chmod 0600, $self->certificate_temp;
    chmod 0600, $self->cert_key_temp;
}

sub _openssl_config_body {
    my $self = shift;
    my ($canonical, @names, %done);
    foreach my $name (@{$self->names}) {
        die "Duplicated name $name!"  if $done{$name};
        $canonical ||= $name;
        push @names, $name;
        $done{$name}++;
    }
    die "No names passed!" unless $canonical && @names;
    my $names_string = join(',', map { "DNS:$_"} @names);
    my $config_body  = << "CONF";
[ req ]
default_bits              = 2048
distinguished_name        = req_distinguished_name
req_extensions            = req_ext

[ req_distinguished_name ]
commonName                = fqn Hostname
commonName_default        = $canonical
commonName_max            = 64

[ req_ext ]
subjectAltName            = \@alt_names

[SAN]
subjectAltName            = $names_string

CONF
    return $config_body;
}

sub fetch {
    my $self = shift;
    my $full_chain;
    try {
        my $acme = Protocol::ACME->new(host => $self->host,
                                       account_key => $self->account_key,
                                       debug => 1,
                                       mailto => $self->mailto);
        $acme->directory;
        $acme->register;
        $acme->accept_tos;
        foreach my $name (@{ $self->names }) {
            $acme->authz($name);
            my $challenge = Protocol::ACME::Challenge::LocalFile
              ->new({ www_root => $self->root });
            $acme->handle_challenge($challenge);
            $acme->check_challenge;
            $acme->cleanup_challenge($challenge);
        }
        my $der = $acme->sign($self->certificate_temp);
        my $chain_der = $acme->chain;
        $full_chain = $self->_convert_to_pem($der) . $self->_convert_to_pem($chain_der);
    } catch { warn "Failed with $_" };
    return $full_chain;
}

sub _convert_to_pem  {
    my ($self, $der) = @_;
    my $pem = Crypt::OpenSSL::X509->new_from_string($der, 'DER')->as_string('PEM');
    return $pem;
}

sub process {
    my $self = shift;
    $self->make_csr;
    if (my $fullchain = $self->fetch) {
        # replace key and cert.
        # we have: fullchain.pem, key.pem, account_key.pem
        # account_key.pem shouldn't change if it exists.
        foreach my $file ('key.pem', 'fullchain.pem') {
            my $path = path($self->directory, $file);
            my $new = path($self->directory, $file . '.new');
            if ($file eq 'fullchain.pem') {
                $new->spew($fullchain);
            }
            elsif ($file eq 'key.pem') {
                path($self->cert_key_temp)->move("$new");
            }
            if ($path->exists) {
                my $backup = path($self->directory, $file . $self->now_string);
                $path->move("$backup");
            }
            $new->move("$path");
        }
        # and that's it I think.
    }
    else {
        warn "Let's encrypt failed\n";
    }
}


1;
