#!perl
use Try::Tiny;
sub {
    my $schema = shift;
    my $guard = $schema->txn_scope_guard;
    foreach my $text ($schema->resultset('Title')->all) {
        $text->text_html_structure(1); # force
    }
    $guard->commit;
}
