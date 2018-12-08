#!/usr/bin/env perl
use ExtUtils::MakeMaker::CPANfile;
use File::ShareDir::Install;

my @exe_files = glob 'script/amusewiki-*';

install_share 'share';

WriteMakefile(
        NAME => 'AmuseWikiFarm',
        LICENSE => 'perl',
        EXE_FILES => \@exe_files,
);

package MY;
use File::ShareDir::Install qw(postamble);
