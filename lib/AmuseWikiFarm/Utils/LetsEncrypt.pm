package AmuseWikiFarm::Utils::LetsEncrypt;

# logic and code blatantly stolen from https://github.com/oetiker/AcmeFetch.

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
        $file->chmod(0600);
    }
    # this is not a Path::Tiny because it's a fixed one
    return "$file";
}

has now_string => (is => 'ro', default => sub { my $now = DateTime->now;
                                                return '.' . $now->ymd . '-' . $now->epoch });

has csr => (is => 'lazy', isa => Object);

sub _build_csr {
    my $self = shift;
    return path($self->working_directory, 'csr.pem');
}

has key => (is => 'lazy', isa => Object);

sub _build_key {
    my $self = shift;
    return path($self->working_directory, 'key.pem');
}

has cert => (is => 'lazy', isa => Object);

sub _build_cert {
    my $self = shift;
    return path($self->working_directory, 'cert.pem');
}

has chain => (is => 'lazy', isa => Object);

sub _build_chain {
    my $self = shift;
    return path($self->working_directory, 'chain.pem');
}

has fullchain => (is => 'lazy', isa => Object);

sub _build_fullchain {
    my $self = shift;
    return path($self->working_directory, 'fullchain.pem');
}

has live_csr => (is => 'lazy', isa => Object);

sub _build_live_csr {
    my $self = shift;
    return path($self->directory, 'csr.pem');
}

has live_key => (is => 'lazy', isa => Object);

sub _build_live_key {
    my $self = shift;
    return path($self->directory, 'key.pem');
}

has live_cert => (is => 'lazy', isa => Object);

sub _build_live_cert {
    my $self = shift;
    return path($self->directory, 'cert.pem');
}

has live_chain => (is => 'lazy', isa => Object);

sub _build_live_chain {
    my $self = shift;
    return path($self->directory, 'chain.pem');
}

has live_fullchain => (is => 'lazy', isa => Object);

sub _build_live_fullchain {
    my $self = shift;
    return path($self->directory, 'fullchain.pem');
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
            -keyout => $self->key->stringify,
            -out  => $self->csr->stringify,
            -config => "$config") == 0 or die "Failed to create cert";
    $self->csr->chmod(0600);
    $self->key->chmod(0600);
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
        my $der = $acme->sign($self->csr->stringify);
        my $chain = $acme->chain;
        my $der_pem = $self->_convert_to_pem($der);
        my $chain_pem = $self->_convert_to_pem($chain);
        $self->fullchain->spew($der_pem, $chain_pem);
        $self->cert->spew($der_pem);
        $self->chain->spew($chain_pem);
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
    return unless $self->self_check;
    $self->make_csr;
    if (-f $self->key and -f $self->csr) {
        if ($self->fetch and -f $self->fullchain) {
            $self->_backup_and_install;
            # create an hidded directory
            return 1;
        }
    }
    return;
}

sub _backup_and_install {
    my $self = shift;
    my $backup = path($self->directory, $self->now_string);
    $backup->mkpath;
    foreach my $method (qw/key csr cert chain fullchain/) {
        my $live = "live_" . $method;
        $self->$live->copy("$backup") if $self->$live->exists;
        # spew is atomic
        $self->$live->spew($self->$method->slurp);
        $self->$live->chmod(0600);
    }
}

sub live_cert_object {
    my $self = shift;
    # we check the fullchain because the existing setup created only them
    my $cert = $self->live_fullchain;
    my $obj;
    if (-f $cert) {
        try {
            $obj = Crypt::OpenSSL::X509->new_from_file($cert->stringify);
        } catch {
            warn "$_";
            $obj = undef
        };
    }
    return $obj;
}

sub live_cert_names_ok {
    my $self = shift;
    my $ok;
    if (my $x509 = $self->live_cert_object) {
        try {
            my %dns;
            if ($x509->subject =~ m{CN=([^,/\s]+)}) {
                $dns{$1} = 1;
            }
            if (my $san = $x509->extensions_by_oid->{"2.5.29.17"}) {
                map { /DNS:([^\s]+)/ and $dns{$1} = 1 } split(/\s*,\s*/, $san->to_string);
            }
            my $missing = 0;
            foreach my $name (@{$self->names}) {
                unless ($dns{$name}) {
                    warn "Missing $name";
                    $missing++;
                }
            }
            $ok = !$missing;
        } catch {
            warn $_;
            $ok = 0;
        }
    }
    return $ok;
}

sub live_cert_expiration_ok {
    my $self = shift;
    if (my $x509 = $self->live_cert_object) {
        if ($x509->checkend(60 * 60 * 24 * 30)) {
            return 0;
        }
        else {
            return 1;
        }
    }
}

sub live_cert_is_valid {
    my $self = shift;
    if ($self->live_cert_names_ok && $self->live_cert_expiration_ok) {
        return 1;
    }
    return 0;
}

sub self_check {
    my $self = shift;
    # this is naive check, but better than nothing
    my $location = path($self->root, '.well-known', 'acme-challenge');
    $location->mkpath;
    my $now = time();
    my $failed = 0;
    foreach my $name (@{ $self->names }) {
        my $filename = $name . $now;
        $filename =~ s/^[a-z0-9]//g;
        my $check_file = path($location, $filename);
        $check_file->spew('OK');
        my $response = HTTP::Tiny->new
          ->get('http://' . $name . '.well-known/acme-challenge/' . $filename);
        unless ($response->{success}) {
            warn "$name couldn't be verified\n";
            $failed++;
        }
        $check_file->remove;
    }
    return !$failed;
}

1;
