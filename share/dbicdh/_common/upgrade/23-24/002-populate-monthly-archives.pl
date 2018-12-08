sub {
    my $schema = shift;
    foreach my $site ($schema->resultset('Site')->all) {
        print "Populating monthly archives for " . $site->id . "\n";
        $site->populate_monthly_archives;
    }
}
