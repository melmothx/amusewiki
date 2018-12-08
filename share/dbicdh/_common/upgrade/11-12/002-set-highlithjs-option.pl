sub {
    my $schema = shift;
    $schema->resultset('SiteOption')->search({
                                              option_name => 'use_js_highlight',
                                              option_value => { '!=' => '' }
                                             })
      ->update({ option_value => "perl xml tex sql bash markdown diff json javascript python ruby" });
}
