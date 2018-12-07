#!/usr/bin/env perl
use ExtUtils::MakeMaker::CPANfile;

my @exe_files = glob 'script/amusewiki-*';

WriteMakefile(
        NAME => 'AmuseWikiFarm',
        LICENSE => 'perl',
        EXE_FILES => \@exe_files,
);
