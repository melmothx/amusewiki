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

has names => (is => 'ro', isa => ArrayRef[Str], required => 1);

has mailto => (is => 'ro', isa => Str, required => 1);

has working_directory => (is => 'ro', isa => Object,
                          default => sub { Path::Tiny->tempdir });

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

has now_string => (is => 'ro', default => sub { my $now = DateTime->now;
                                                return '.' . $now->ymd . '-' . $now->epoch });

has csr => (is => 'lazy', isa => Str);

sub _build_csr {
    my $self = shift;
    return path($self->working_directory, 'csr.pem')->stringify;
}

has key => (is => 'lazy', isa => Str);

sub _build_key {
    my $self = shift;
    return path($self->working_directory, 'key.pem')->stringify;
}

has fullchain => (is => 'lazy', isa => Str);

sub _build_fullchain {
    my $self = shift;
    return path($self->working_directory, 'fullchain.pem')->stringify;
}

has live_csr => (is => 'lazy', isa => Str);

sub _build_live_csr {
    my $self = shift;
    return path($self->directory, 'csr.pem')->stringify;
}

has live_key => (is => 'lazy', isa => Str);

sub _build_live_key {
    my $self = shift;
    return path($self->directory, 'key.pem')->stringify;
}

has live_fullchain => (is => 'lazy', isa => Str);

sub _build_live_fullchain {
    my $self = shift;
    return path($self->directory, 'fullchain.pem')->stringify;
}

sub staging_host { 'acme-staging.api.letsencrypt.org' };

sub live_host { 'acme-v01.api.letsencrypt.org' };

has host => (is => 'lazy', isa => Str);

sub _build_host {
    my $self = shift;
    if ($self->staging) {
        return $self->staging_host;
    }
    else {
        return $self->live_host;
    }
}


sub make_csr {
    my $self = shift;
    my $config = Path::Tiny->tempfile(SUFFIX => '.cfg');
    $config->spew($self->_openssl_config_body);
    system (qw(openssl req -nodes -newkey rsa:2048 -batch -reqexts SAN -outform PEM
               -keyform PEM),
            -keyout => $self->key,
            -out  => $self->csr,
            -config => "$config") == 0 or die "Failed to create cert";
    chmod 0600, $self->csr;
    chmod 0600, $self->key;
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
    my ($self, $live) = @_;
    my $ok;
    my $host = $self->staging_host;
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
        my $der = $acme->sign($self->csr);
        my $chain_der = $acme->chain;
        path($self->fullchain)->spew($self->_convert_to_pem($der),
                                     $self->_convert_to_pem($chain_der));
        $ok = 1;
    } catch { warn "Certificate fetching failed with $_" };
    return $ok;
}

sub _convert_to_pem  {
    my ($self, $der) = @_;
    my $pem = Crypt::OpenSSL::X509
      ->new_from_string($der, Crypt::OpenSSL::X509::FORMAT_ASN1)
      ->as_string(Crypt::OpenSSL::X509::FORMAT_PEM);
    return $pem;
}

sub process {
    my $self = shift;
    $self->make_csr;
    if (-f $self->key and -f $self->csr) {
        if ($self->fetch and -f $self->fullchain) {
            my $backup = path($self->directory, $self->now_string);
            $backup->mkpath;
            path(self->live_key)->copy("$backup");
            path(self->live_csr)->copy("$backup");
            path(self->live_fullchain)->copy("$backup");
            # replace key and cert. we have: fullchain.pem, key.pem,
            # account_key.pem account_key.pem shouldn't change if it
            # exists. this tries to be atomic, but there is a slight
            # race condition. We'll have to live with this
            path($self->key)->move($self->live_key);
            path($self->fullchain)->move($self->live_fullchain);
            path($self->csr)->move($self->live_csr);
        }
        # and that's it I think.
    }
    else {
        warn "Let's encrypt failed\n";
    }
}


1;
