use DateTime;
use Try::Tiny;

sub {
    my $schema = shift;
    try {
        my $older_than  = DateTime->new(year => 2017,
                                        month => 4,
                                        day => 1)->epoch;
        foreach my $s ($schema->resultset('Site')->search({ nocoverpage => 1 })) {
            foreach my $text ($s->titles->status_is_published_or_deferred
                              ->search({ f_timestamp_epoch => { '>' => $older_than } })) {
                print "Scheduled a rebuild for " . $s->canonical . $text->full_uri . "\n";
                $s->jobs->rebuild_add({ id => $text->id });;
            }
        };
    } catch {
        my $error = $_;
        print "$error\n";

        print <<HELP;

We tried to rebuild all the files from april 2017 up to today in the
sites where nocoverpage is set to true (which was too agressive and
basically always prevented a proper coverpage when it was supposed to
do so only if the table of contents was missing). This failed
(probably this is a multistep upgrade). You are suggested to initiate
a full site rebuild from the admin console.

HELP
    };
}



          
