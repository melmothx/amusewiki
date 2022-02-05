#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 69;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Amuse;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

check_uri_fragment('等等', '等等');
check_uri_fragment('/test/', 'test');
check_uri_fragment('等等/test/', '等等-test');
check_uri_fragment("<互助>", "互助");
check_uri_fragment("/互助主义/", "互助主义");
check_uri_fragment("|个人主义|", "个人主义");
check_uri_fragment("'克鲁泡特金'", "克鲁泡特金");
check_uri_fragment('"约瑟夫·德雅克"', "约瑟夫-德雅克");
check_uri_fragment("雇佣劳动", "雇佣劳动");
check_uri_fragment("阿拉贡！", "阿拉贡");
check_uri_fragment("俄罗斯", "俄罗斯");
check_uri_fragment("民粹派", "民粹派");
check_uri_fragment("工厂民主", "工厂民主");
check_uri_fragment("苏丹", "苏丹");
check_uri_fragment("麦克斯·施蒂纳", "麦克斯-施蒂纳");
check_uri_fragment("威廉·吉利斯", "威廉-吉利斯");
check_uri_fragment("科技", "科技");
check_uri_fragment("混乱", "混乱");
check_uri_fragment("恩佐·马尔图奇", "恩佐-马尔图奇");
check_uri_fragment("ziq", "ziq");
check_uri_fragment("反左派", "反左派");
check_uri_fragment("左翼联合", "左翼联合");
check_uri_fragment("克里斯托弗·Wong", "克里斯托弗-wong");
check_uri_fragment("CrimethInc.", "crimethinc");
check_uri_fragment("伦佐·诺瓦托瑞", "伦佐-诺瓦托瑞");
check_uri_fragment("反工作", "反工作");
check_uri_fragment("反群", "反群");
check_uri_fragment("BASF", "basf");
check_uri_fragment("大卫·格雷伯", "大卫-格雷伯");
check_uri_fragment("Tiqqun", "tiqqun");
check_uri_fragment("后左派", "后左派");
check_uri_fragment("中国", "中国");
check_uri_fragment("文言文", "文言文");
check_uri_fragment("敏", "敏");
check_uri_fragment("历史，韩国，新民", "历史-韩国-新民");
check_uri_fragment("历史", "历史");
check_uri_fragment("韩国", "韩国");
check_uri_fragment("新民", "新民");
check_uri_fragment("沙织", "沙织");
check_uri_fragment("后无政府主义", "后无政府主义");
check_uri_fragment("后结构主义", "后结构主义");
check_uri_fragment("无神论", "无神论");
check_uri_fragment("古典", "古典");
check_uri_fragment("宗教", "宗教");
check_uri_fragment("国家", "国家");
check_uri_fragment("阿卜杜拉·奥贾兰", "阿卜杜拉-奥贾兰");
check_uri_fragment("民主邦联主义", "民主邦联主义");
check_uri_fragment("米哈伊尔·巴枯宁", "米哈伊尔-巴枯宁");
check_uri_fragment("无神论，古典，宗教，国家", "无神论-古典-宗教-国家");
check_uri_fragment("叛乱", "叛乱");
check_uri_fragment("共产化", "共产化");
check_uri_fragment("中文无治主义图书馆", "中文无治主义图书馆");
check_uri_fragment("使用手册", "使用手册");
check_uri_fragment("叛乱无政府主义", "叛乱无政府主义");
check_uri_fragment("隐形委员会", "隐形委员会");
check_uri_fragment("艾力格·马拉泰斯塔", "艾力格-马拉泰斯塔");
check_uri_fragment("无政府共产主义", "无政府共产主义");
check_uri_fragment("意大利无政府主义", "意大利无政府主义");
check_uri_fragment("问答", "问答");
check_uri_fragment("伦佐·纳威托", "伦佐-纳威托");
check_uri_fragment("虚无主义", "虚无主义");
check_uri_fragment("厄休拉·勒古恩", "厄休拉-勒古恩");
check_uri_fragment("虚构文学", "虚构文学");
check_uri_fragment("加文·曼德尔-格利森", "加文-曼德尔-格利森");


my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;
my $site = create_site($schema, '0unicodeuris0');
$site->site_options->update_or_create({ option_name => 'category_uri_use_unicode',
                                        option_value => 1 });

{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;

    my $muse = <<'MUSE';
#title 等等
#author 来 来/来
#topics 等等, /test/, <xx>, "test-me", //等等等等//, 就是这个
#lang en
#pubdate 2022-02-05T09:24:24

就是这个
MUSE
    $rev->edit($muse);
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->categories->find({ type => 'topic', uri => '等等' });
ok $site->categories->find({ type => 'author', uri => '来-来-来' });

$site->site_options->update_or_create({ option_name => 'category_uri_use_unicode',
                                        option_value => 0 });

$site->categories->delete;
$site->get_from_storage->compile_and_index_files([$site->titles->first->filepath_for_ext('muse')], sub { diag @_ });

ok !$site->categories->find({ type => 'topic', uri => '等等' });
ok $site->categories->find({ type => 'topic', uri => 'deng-deng' });
ok !$site->categories->find({ type => 'author', uri => '来-来-来' });

sub check_uri_fragment {
    my ($piece, $exp) = @_;
    is AmuseWikiFarm::Utils::Amuse::unicode_uri_fragment($piece), $exp, "$exp OK";
}
