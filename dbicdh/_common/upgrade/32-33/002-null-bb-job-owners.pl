sub {
    my $schema = shift;
    $schema->resultset('Job')->search({ username => 'anonymous' })->update({ username => undef });
}
