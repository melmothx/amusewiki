package AmuseWikiFarm::Role::Controller::ListingDisplay;
use MooseX::MethodAttributes::Role;

requires qw/base/;

use AmuseWikiFarm::Log::Contextual;

sub listing :Chained('base') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In listing" };
    my $rs = delete $c->stash->{texts_rs};
    # these should be cached if the user doesn't exist
    my $cache = $c->model('Cache',
                          site_id => $c->stash->{site}->id,
                          type => 'library',
                          subtype => $c->stash->{f_class},
                          # here we use the language set in the app
                          lang => $c->stash->{current_locale_code},
                          resultset => $rs,
                          no_caching => !!$c->user_exists,
                         );
    $c->stash(texts => $cache->texts,
              pager => $cache->pager,
              text_count => $cache->text_count,
              show_pager => $c->stash->{site}->pagination_needed($cache->text_count),
              template => 'library.tt');
}

1;
