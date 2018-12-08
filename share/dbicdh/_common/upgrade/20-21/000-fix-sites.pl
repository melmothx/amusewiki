sub {
    my $schema = shift;
    foreach my $column (qw/ssl_cert 
                           ssl_ca_cert
                           ssl_chained_cert
                           ssl_key
                           logo/) {
        $schema->resultset('Site')->search({ $column => undef })->update({ $column => '' });
    }
}
