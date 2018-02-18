package AmuseWikiFarm::Middleware::WeakETag;
use strict;
use warnings;
use Digest::SHA;
use Plack::Util;

use parent qw/Plack::Middleware/;

sub call {
    my $self = shift;
    my $res  = $self->app->(@_);
    $self->response_cb(
        $res,
        sub {
            my $res     = shift;
            my $headers = $res->[1];
            # algo stolen from Franck Cuny's https://metacpan.org/release/Plack-Middleware-ETag
            return unless defined $res->[2];
            return if Plack::Util::header_exists($headers, 'ETag');

            my $digest;

            if ( Plack::Util::is_real_fh( $res->[2] ) ) {
                my @stats = stat $res->[2];
                $digest = qq{$stats[1]-$stats[9]-$stats[7]};
            } else {
                $digest = Digest::SHA->new('SHA-1')->add(@{$res->[2]})->hexdigest;
            }

            Plack::Util::header_set($headers, ETag => qq{W/"$digest"});
            return;
        }
    );
}

1;

