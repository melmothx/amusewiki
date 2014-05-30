#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Data::Dumper;
use AmuseWikiFarm::Schema;


my $schema = AmuseWikiFarm::Schema->connect('amuse');


my $site = $schema->resultset('Site')->find('0blog0');

# use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
#                                    muse_file_info
#                                    muse_filepath_is_valid
#                                    muse_naming_algo/;
# 
# my $details = muse_file_info ('repo/0blog0/f/ft/f-t-testimage.png', 'repo/0blog0');
# 
# print Dumper($details);
# 
# $site->attachments->update_or_create($details, { key => 'uri_site_id_unique' });
# 
# $details->{f_timestamp_epoch} = 1111;
# 
# $site->attachments->update_or_create($details, { key => 'uri_site_id_unique' });
# 
$schema->resultset('User')->update_or_create({
                                                         username => 'pinco',
                                                         password => 'pallino',
                                                         active   => 1,
                                                        }); #, { key => 'username_unique' });


my $user = $schema->resultset('User')->update_or_create({
                                username => 'pinco',
                                password => 'xxx',
                                active   => 0,
                               }); #, { key => 'username_unique' });

$site->add_to_users($user) unless $user->sites->find($site->id);

is $site->users->find( { username => 'pinco' } )->password, 'xxx';

$user->delete;


