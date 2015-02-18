#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use utf8;
use strict;
use warnings;
use Test::More tests => 22;
use Data::Dumper;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $users = $schema->resultset('User');

my %tests = (
             invalid => [
                         {
                          username => 'asdf asdf asdfasdf',
                          password => '',
                         },
                         undef,
                         'Invalid username',
                         'Password too short',
                        ],
             emailonly => [
                           { email => 'pinco@amusewiki.org' },
                           { email => 'pinco@amusewiki.org' },
                          ],
             blankpassword =>[
                              {
                               email => 'pinco@amusewiki.org',
                               password => undef,
                              },
                              undef,
                              'Password too short',
                             ],
             fields_too_long => [
                                 {
                                  email => 'abc' x 100,
                                  password => 'abc' x 100,
                                  passwordrepeat => '',
                                 },
                                 undef,
                                 'Some fields are too long',
                                ],
             invalid_name => [
                              {
                               email => 'info@amusewiki.org',
                               emailrepeat => 'info@amusewiki.org',
                               username => 'pippo x',
                               password => '123412341234',
                               passwordrepeat => '123412341234',
                              },
                              undef,
                              'Invalid username',
                             ],
             valid => [
                       {
                        email => 'info@amusewiki.org',
                        emailrepeat => 'info@amusewiki.org',
                        username => 'pippo',
                        password => '123412341234',
                        passwordrepeat => '123412341234',
                       },
                       {
                        username => 'pippo',
                        password => '123412341234',
                        email => 'info@amusewiki.org',
                       },
                      ],

             valid_no_email_repeat => [
                       {
                        email => 'info@amusewiki.org',
                        username => 'pippo',
                        password => '123412341234',
                        passwordrepeat => '123412341234',
                       },
                       {
                        username => 'pippo',
                        password => '123412341234',
                        email => 'info@amusewiki.org',
                       },
                      ],

             invalid_no_password_repeat => [
                                            {
                                             email => 'info@amusewiki.org',
                                             emailrepeat => 'info@amusewiki.org',
                                             username => 'pippo',
                                             password => '123412341234',
                                            },
                                            undef,
                                            'Passwords do not match',
                                           ],
             invalid_no_pwd_match => [
                                      {
                                       email => 'info@amusewiki.org',
                                       emailrepeat => 'info@amusewiki.org',
                                       username => 'pippo',
                                       password => '123412341234x',
                                       passwordrepeat => '123412341234',
                                      },
                                      undef,
                                      'Passwords do not match',
                                     ],

             invalid_no_email_match => [
                                      {
                                       email => 'info@amusewiki.org',
                                       emailrepeat => 'info@amusewiki.orgx',
                                       username => 'pippo',
                                       password => '123412341234',
                                       passwordrepeat => '123412341234',
                                      },
                                      undef,
                                      'Emails do not match',
                                     ],
             invalid_email => [
                               {
                                email => 'alsdflasdofj',
                               },
                               undef,
                               'Invalid email',
                              ],
            );

foreach my $test (keys %tests) {
    # print Dumper($tests{$test});
    test_validation($users, $test, @{$tests{$test}});
}


sub test_validation {
    my ($users, $name, $input, $output, @expected) = @_;
    my ($out, @errors) = $users->validate_params(%$input);
    is_deeply($out, $output, "$name: Output  ok")
      or diag Dumper($out, $output);
    is_deeply(\@errors, \@expected, "$name: errors ok")
      or diag Dumper(\@errors, \@expected);
}
