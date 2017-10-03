#!perl
use Try::Tiny;
sub {
    my $schema = shift;
    foreach my $text ($schema->resultset('Title')->all) {
        $text->text_html_structure(1); # force
    }
}
