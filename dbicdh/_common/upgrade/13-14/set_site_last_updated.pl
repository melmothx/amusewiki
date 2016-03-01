use DateTime;
sub {
    my $schema = shift;
    $schema->resultset('Site')->update({ last_updated => DateTime->now });
}
