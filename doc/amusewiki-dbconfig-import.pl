#!/usr/bin/perl

use strict;
use warnings;
use YAML qw/LoadFile/;
use File::Basename qw/fileparse/;

# this script is for dbconfig-common and is run in this lame way:
# ( cat $inputfile; cat << EOF ) | perl
# print "dbc_dbuser='\$$dbuser_varname'\n" if("$use_dbuser");
# print "dbc_dbpass='\$$dbpass_varname'\n" if("$use_dbpass");
# print "dbc_basepath='\$$basepath_varname'\n" if("$use_basepath");
# print "dbc_dbname='\$$dbname_varname'\n" if("$use_dbname");
# print "dbc_dbserver='\$$dbserver_varname'\n" if("$use_dbserver");
# print "dbc_dbport='\$$dbport_varname'\n" if("$use_dbport");
# print "dbc_dbtype='\$$dbtype_varname'\n" if("$use_dbtype");
# EOF
# ;;
# the the result is eval'ed by the shell

# obviously these lexicals are going to shoot us in the foot at some
# point. But let's hope it's a temporary solution

my $dbuser   = '';
my $dbpass   = '';
my $dbname   = '';
my $dbserver = '';
my $dbport   = '';
my $basepath = '';
my $dbtype   = '';

my $dbic = $ENV{AMW_LOAD_DBIC_FILE} || '/var/lib/amusewiki/dbic.yaml';
if (-f $dbic) {
    my $vars = LoadFile($dbic);
    if (my $amw = $vars->{amuse}) {
        my $dsn = $amw->{dsn};
        if (parse_dsn($dsn)) {
            $dbuser = $amw->{user};
            $dbpass = $amw->{password};
        }
    }
}

sub parse_dsn {
    my $dsn = shift;
    my ($dbi, $type, $options) = split(/:/, $dsn, 3);
    my %types = (
                 Pg => 'pgsql',
                 mysql => 'mysql',
                 SQLite => 'sqlite3',
                );
    if ($dbtype = $types{$type}) {
        my %map = (
                   dbname => \$dbname,
                   database => \$dbname,
                   host => \$dbserver,
                   hostaddr => \$dbserver,
                   port => \$dbport,
                  );
        if ($options =~ m/;/) {
            my @options = split(/;/, $options);
            foreach my $opt (@options) {
                my ($name, $value) = split(/=/, $opt);
                if (my $set = $map{$name}) {
                    $$set = $value;
                }
                else {
                    warn "Unhandled option $name $value";
                }
            }
        }
        elsif ($dbtype eq 'sqlite3') {
            if ($options =~ m/\//) {
                ($dbname, $basepath) = fileparse($options);
            }
            else {
                $dbname = $options;
                $basepath = '/var/lib/amusewiki';
            }
            $basepath =~ s/\/$//;
        }
        else {
            $dbname = $options;
        }
        return 1;
    }
}

if (@ARGV) {
    print "dbuser   \"$dbuser\"   \n";
    print "dbpass   \"$dbpass\"   \n";
    print "dbname   \"$dbname\"   \n";
    print "dbserver \"$dbserver\" \n";
    print "dbport   \"$dbport\"   \n";
    print "basepath \"$basepath\" \n";
    print "dbtype   \"$dbtype\"   \n";
}
