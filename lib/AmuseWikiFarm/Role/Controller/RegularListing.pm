package AmuseWikiFarm::Role::Controller::RegularListing;
use MooseX::MethodAttributes::Role;

requires qw/pre_base/;

sub base :Chained('pre_base') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->log->debug('in regular listing base');
    # if the user is logged in, give him access to deferred as well
    my $titles = $c->stash->{site}->titles;
    my $rs;
    if ($c->user_exists) {
        $rs = $titles->published_or_deferred_texts;
    }
    else {
        $rs = $titles->published_texts;
    }
    $c->stash(
              f_class => 'text',
              texts_rs => $rs,
              page_title => $c->loc('Full list of texts'),
              nav => 'titles',
             );
}

1;
