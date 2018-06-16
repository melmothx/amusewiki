package AmuseWikiMeta::View::HTML;

use base qw/Catalyst::View/;
use Template::Tiny;

sub process {
    my ($self, $c) = @_;
    my $out;
    my $body = $c->stash->{html_source}->slurp_utf8;
    my $template = $c->stash->{html_layout}->slurp_utf8;
    my ($title) = $body =~ m/<div\s+id="amw-page-title"\s*>(.+?)<\/div>/s;
    Template::Tiny->new->process(\$template, {
                                              body => $body,
                                              title => $title,
                                             }, \$out);
    $c->response->content_type('text/html; charset=UTF-8');
    $c->response->body($out);
}

1;
