sub {
    my $schema = shift;
    $schema->resultset('TitleStat')->delete;
}
