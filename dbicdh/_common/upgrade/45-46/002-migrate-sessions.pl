use AmuseWikiFarm;
use Cache::FastMmap;
use File::Copy;
use Data::Dumper::Concise;

sub {
my $schema = shift;
my %sessions;
my $config = AmuseWikiFarm->_session_plugin_config;
unless ($config->{cache_size} && $config->{storage} && -f $config->{storage}) {
    print "No need to migrate, exiting\n";
    exit;
}
print Dumper($config);
File::Copy::copy($config->{storage}, $config->{storage} . '~' . time())
    or die "$config->{storage}: Couldn't make a backup $!";

my $c = Cache::FastMmap->new(raw_values => 0,
                             unlink_on_exit => 0,
                             init_file => 0,
                             cache_size => $config->{cache_size},
                             share_file => $config->{storage},
                            );
my @all = $c->get_keys(0);
print "Retrieving " . scalar(@all) . " keys\n";
while (@all) {
    my $sid = shift @all;
    my ($id, $field) = AmuseWikiFarm::Schema::ResultSet::AmwSession::_split_id_and_field($sid);
    $field =~ s/_data$//;
    my $value = $c->get($sid);
    $sessions{$id}{$field} = $value;
    if ($field eq 'session') {
        $sessions{$id}{site_id} = $value->{site_id};
    }
}

# print Dumper(\%sessions);

my %sites = map { $_->id => 1 } $schema->resultset('Site')->all;

my $now = time();
my $guard = $schema->txn_scope_guard;
my $importer = $schema->resultset('AmwSession');
foreach my $sid (keys %sessions) {
    if (my $site_id = $sessions{$sid}{site_id}) {
        if ($sites{$site_id}) {
            if ($sessions{$sid}{expires} and $sessions{$sid}{expires} > $now) {
                foreach my $f (qw/expires session flash/) {
                    if (exists $sessions{$sid}{$f}) {
                        $importer->store_session_data($site_id, "$f:$sid", $sessions{$sid}{$f});
                    }
                }
            }
        }
    }
}
File::Copy::move($config->{storage}, $config->{storage} . '~' . time())
  or die "$config->{storage}: Couldn't move it $!";
$guard->commit;
print "Migrated " . $schema->resultset('AmwSession')->count . " sessions\n";
}
