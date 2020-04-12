-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/58/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/59/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `site` ADD COLUMN `git_token` text NULL,
                   CHANGE COLUMN `fixed_category_list` `fixed_category_list` text NULL,
                   CHANGE COLUMN `mail_notify` `mail_notify` text NULL,
                   CHANGE COLUMN `mail_from` `mail_from` text NULL;

;

COMMIT;

