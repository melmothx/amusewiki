package AmuseWikiFarm::Utils::CgitSetup;

use Moose;
use namespace::autoclean;
use AmuseWikiFarm::Log::Contextual;
use Cwd;
use File::Spec;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use File::Temp;
use File::Copy qw/copy move/;

has amw_home => (is => 'ro',
                 isa => 'Str',
                 default => sub { getcwd() });

has src => (is => 'ro',
            isa => 'Str',
            lazy => 1,
            builder => '_build_src');

sub _build_src {
    catdir(shift->amw_home, qw/opt src/);
}

has cgitsrc => (is => 'ro',
                isa => 'Str',
                lazy => 1,
                builder => '_build_cgitsrc');

sub _build_cgitsrc {
    catdir(shift->src, 'cgit');
}

has gitsrc => (is => 'ro',
                isa => 'Str',
                lazy => 1,
                builder => '_build_gitsrc');

sub _build_gitsrc {
    catdir(shift->cgitsrc, 'git');
}

has www => (is => 'ro',
            isa => 'Str',
            lazy => 1,
            builder => '_build_www');

sub _build_www {
    catdir(shift->amw_home, qw/root git/);
}

has cgi => (is => 'ro',
            isa => 'Str',
            lazy => 1,
            builder => '_build_cgi');

sub _build_cgi {
    catfile(shift->www, 'cgit.cgi');
}

has cache => (is => 'ro',
              isa => 'Str',
              lazy => 1,
              builder => '_build_cache');

sub _build_cache {
    my $cache = catdir(shift->amw_home, qw/opt cache cgit/);
    make_path($cache) unless -d $cache;
    return $cache;
}

has etc => (is => 'ro',
            isa => 'Str',
            lazy => 1,
            builder => '_build_etc');

sub _build_etc {
    my $etc = catdir(shift->amw_home, qw/opt etc/);
    make_path($etc) unless -d $etc;
    return $etc;
}

has cgitrc => (is => 'ro',
               isa => 'Str',
               lazy => 1,
               builder => '_build_cgitrc');

sub _build_cgitrc {
    catfile(shift->etc, 'cgitrc');
}

has lib => (is => 'ro',
            isa => 'Str',
            lazy => 1,
            builder => '_build_lib');

has schema => (is => 'ro',
               isa => 'Object');
               
has hostname => (is => 'ro',
                 isa => 'Str');

sub _build_lib {
    catdir(shift->amw_home, qw/opt usr/);
}

sub create_skeleton {
    my $self = shift;
    foreach my $dir (qw/src cache etc lib/) {
        make_path($self->$dir, { verbose => 1 }) unless -d $self->$dir;
    }
}

sub configure {
    my $self = shift;
    my $hostname = $self->hostname;
    my $fh = File::Temp->new(TMPDIR => 1, UNLINK => 0, TEMPLATE => 'cgitXXXXXXXX');
    binmode $fh, ':encoding(utf-8)';
    my $schema = $self->schema;
    die "Missing schema, can't configure" unless $schema;
    my $cache_root = $self->cache;
    print $fh "####### automatically generated on " . localtime() . " ######\n\n";
    print $fh <<"CONFIG";
virtual-root=/git
enable-index-owner=0
robots="noindex, nofollow"
cache-size=1000
cache-root=$cache_root
enable-commit-graph=1
embedded=1
logo=/git/cgit.png
CONFIG
    foreach my $site ($schema->resultset('Site')->all) {
        next unless $site->repo_is_under_git;
        my $path = File::Spec->rel2abs(catdir($self->amw_home, 'repo',
                                              $site->id, ".git"));
        unless (-d $path) {
            log_debug { "Repo $path not found!, skipping" };
            next;
        }
        print $fh "repo.url=" . $site->id . "\n";
        print $fh "repo.path=" . $path . "\n";
        print $fh "repo.desc=" . $site->sitename . "\n" if $site->sitename;
        if (-f catfile($path, 'git-daemon-export-ok')) {
            my $githostname = $hostname || $site->canonical;
            print $fh "repo.clone-url=git://$githostname/git/" . $site->id .
              ".git\n";
        }
        print $fh "\n\n";
        log_debug { "Exported " . $site->id . " into cgit" };
    }
    close $fh;
    if (-f $self->cgitrc) {
        copy($self->cgitrc, $self->cgitrc . "." . time());
    }
    chmod 0644, $fh->filename;
    move($fh->filename, $self->cgitrc) or log_error { "Cannot install " . $self->cgitrc . " $!" };
}

sub cgi_exists {
    my $self = shift;
    if (-f $self->cgi) {
        return 1;
    }
    else {
        return 0;
    }
}


__PACKAGE__->meta->make_immutable;

1;
