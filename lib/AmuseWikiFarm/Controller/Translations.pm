package AmuseWikiFarm::Controller::Translations;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

sub index :Chained('/site_robot_index') :PathPart('translations') :Args {
    my ($self, $c, $lang) = @_;
    my $site = $c->stash->{site};
    my @languages = grep { $_ and /\A[a-z]+\z/ } ($site->locale, $c->stash->{current_locale_code}, $lang);
    my @all = $site->titles->by_lang({ -in => \@languages })->with_uid
      ->search(undef, {
                       columns => [qw/id uid lang/],
                       result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                      });
    my %uids;
    # last (user selected) wins:
    foreach my $l (@languages) {
        foreach my $text (grep { $_->{lang} eq $l } @all) {
            $uids{$text->{uid}} = $text->{id};
        }
    }
    my $rs = $site->titles->search(
                                   { id => { -in => [ values %uids ] } },
                                   { order_by => { -asc => 'uid' } }
                                  );
    $c->stash(texts => $rs);
}

__PACKAGE__->meta->make_immutable;

1;
