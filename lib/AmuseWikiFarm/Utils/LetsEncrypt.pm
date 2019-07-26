package AmuseWikiFarm::Utils::LetsEncrypt;

# logic and code blatantly stolen from https://github.com/oetiker/AcmeFetch.

use Moo;
use Types::Standard qw/Bool ArrayRef Str Object/;
use Path::Tiny;
use Net::ACME2::LetsEncrypt;
use Crypt::OpenSSL::X509;
use DateTime;
use Try::Tiny;
use Data::Dumper;
use AmuseWikiFarm::Log::Contextual;

has staging => (is => 'ro', isa => Bool, default => 1);

has directory => (is => 'ro', isa => Str, required => 1);

has root => (is => 'ro', isa => Str, required => 1);

has web_root => (is => 'lazy', isa => Object);

has timeout => (is => 'ro', default => sub { 120 });

sub _build_web_root {
    my $self = shift;
    my $web_root = path($self->root);
    $web_root->mkpath unless -d $web_root;
    return $web_root;
}

has account_key => (is => 'lazy', isa => Object);

has names => (is => 'ro', isa => ArrayRef[Str], required => 1);

has mailto => (is => 'ro', isa => Str, required => 1);

has working_directory => (is => 'ro', isa => Object,
                          default => sub { Path::Tiny->tempdir });

sub _build_account_key {
    my $self = shift;
    my $file = path($self->directory, 'account_key.pem');
    $file->parent->mkpath unless -d $file->parent;
    unless (-f $file) {
        system(openssl => genrsa => -out => "$file", "2048") == 0
          or die "Cannot create $file!";
        $file->chmod(0600);
    }
    # this is not a Path::Tiny because it's a fixed one
    return $file;
}

has key_id_file => (is => 'lazy', isa => Object);

sub _build_key_id_file {
    my $self = shift;
    return path($self->directory, 'key_id');
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

sub names_as_string {
    my $self = shift;
    return join(' ', @{$self->names});
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

has acme_instance => (is => 'lazy', isa => Object);

sub _build_acme_instance {
    my $self = shift;
    my $key_id;
    if ($self->key_id_file->exists) {
        $key_id = $self->key_id_file->slurp_raw || undef;
    }
    my $acme = Net::ACME2::LetsEncrypt->new(
                                            environment => $self->staging ? 'staging' : 'production',
                                            key => $self->account_key->slurp_raw,
                                            key_id => $key_id,
                                           );
    if (!$acme->key_id) {
        $acme->get_terms_of_service;
        $acme->create_account(termsOfServiceAgreed => 1);
        log_debug { "Created account" };
        $self->key_id_file->spew_raw($acme->key_id);
    }
    else {
        log_debug { $acme->key_id . " exists" };
    }
    return $acme;
}


sub fetch {
    my ($self, $live) = @_;
    my $ok;
    try {
        my $acme = $self->acme_instance;
        my $identifiers = [ map { +{ type => 'dns', value => $_ } } @{$self->names} ];
        Dlog_debug { "identifiers: $_" } $identifiers;
        my $order = $acme->create_new_order(identifiers => $identifiers);
        # authorizations will return url, while get_authorization will get objects.
        my @authzs = map { $acme->get_authorization($_) } $order->authorizations;
        Dlog_debug { "My authorizations: $_" } \@authzs;

        # we need to keep the handlers around, as the file gets
        # removed on destroy.
        my @handlers;
        foreach my $auth (@authzs) {
            my $domain = $auth->identifier->{value};
            log_debug { "Authorizing $domain" };
            # we just want the http-01
            my ($challenge) = grep { $_->type eq 'http-01' } $auth->challenges;
            die "No http-01 challenge returned!" unless $challenge;
            log_debug { $self->web_root };
            # keep it in scope
            my $handler = $challenge->create_handler($acme, $self->web_root);
            $acme->accept_challenge($challenge);
            push @handlers, $handler;
        }
        my $timeout = $self->timeout;

        my %completed_status = (
                                valid => 1,
                                invalid => 1,
                                revoked => 1,
                               );
      POLL:
        while ($timeout > 0) {
            foreach my $auth (@authzs) {
                next if $auth->status eq 'valid';
                my $status = $acme->poll_authorization($auth);
                log_debug { $auth->identifier->{value} . " is $status" };
                last POLL if $status eq 'invalid';
            }
            last POLL unless scalar(grep { !$completed_status{$_->status} } @authzs);
            sleep 1;
            $timeout--;
        }

        if (grep { ($_->status // '') ne 'valid' } @authzs) {
            Dlog_error { "Invalid: $_" } \@authzs;
            die "Invalid authorization";
        }
        $acme->finalize_order($order, $self->csr->slurp_raw);
        while (($order->status ne 'valid') and $timeout > 0) {
            $acme->poll_order($order);
            sleep 1;
            $timeout--;
        }
        die Dumper($order) unless $order->status eq 'valid';

        # write the file, that's it.
        my $full_chain = $acme->get_certificate_chain($order);
        $self->fullchain->spew($full_chain);
        my @certs;
        while ($full_chain =~ m/(-----BEGIN.*?\n.*?-----END.*?\n)/sg) {
            push @certs, $1;
        }
        die "Chain incomplete $full_chain" unless @certs > 1;
        $self->cert->spew($certs[0]);
        $self->chain->spew($certs[1]);
        log_info { "Certificate written to " . $self->fullchain };
        foreach my $c ($self->cert, $self->chain) {
            log_debug { system(openssl => x509 => -in => "$c" => -text => '-noout') };
        }
        $ok = 1;
    } catch {
        my $error = $_;
        log_warn { "Certificate fetching failed with $error for " . $self->names_as_string };
    };
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
            # create an hidden directory
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
            my $error = $_;
            log_warn { $self->names_as_string . " failed to parse $cert object: $error" };
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
                    log_warn { "Missing $name in " . $self->live_fullchain  };
                    $missing++;
                }
            }
            $ok = !$missing;
        } catch {
            my $error = $_;
            log_warn { "$error checking names in " . $self->live_fullchain };
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
        $filename =~ s/[^a-z0-9]//g;
        my $check_file = path($location, $filename);
        $check_file->spew('OK');
        my $response = HTTP::Tiny->new
          ->get('http://' . $name . '/.well-known/acme-challenge/' . $filename);
        Dlog_debug { "Self check: $_" } $response;
        unless ($response->{success}) {
            Dlog_warn { "$name couldn't be self-verified: $_" } $response;
            $failed++;
        }
        $check_file->remove;
    }
    return !$failed;
}

1;
