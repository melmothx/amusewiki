#!perl
use File::Copy qw/move/;
use File::Spec;
use Data::Dumper;
sub {
    my $schema = shift;
    return;

    my $targetdir = File::Spec->catdir(qw/root custom/);
    return unless -d $targetdir;
    opendir (my $dh, $targetdir) or die $!;
    my @files =  grep { -f File::Spec->catfile($targetdir, $_) } readdir($dh);
    closedir $dh;
    print Dumper(\@files);
    my $newdir = 'bbfiles';
    die "Missing $newdir" unless -d $newdir;
    foreach my $file (@files) {
        my $job_id;
        my $slot;
        if ($file =~ m/\A([0-9]+)\.(pdf|epub|sl\.pdf)\z/) {
            $job_id = $1;
            $slot = 'produced';
        }
        elsif ($file =~ m/\Abookbuilder-([0-9]+)\.zip\z/) {
            $job_id = $1;
            $slot = 'sources';
        }
        if ($job_id && $slot) {
            if (my $job = $schema->resultset('Job')->find($job_id)) {
                $job->add_to_job_files({ filename => $file,
                                         slot => $slot,
                                       });
            }
            my $src = File::Spec->catfile($targetdir, $file);
            my $dst = File::Spec->catfile($newdir, $file);
            print "Moving $src to $dst\n";
            move($src, $dst) or die $!;
        }
    }
}
