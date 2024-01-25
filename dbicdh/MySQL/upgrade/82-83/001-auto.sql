-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `site` CHANGE COLUMN `cgit_integration` `cgit_integration` integer(1) NOT NULL DEFAULT 0;

;
ALTER TABLE `users` ADD COLUMN `api_access_token` text NULL,
                    ADD COLUMN `api_access_created` datetime NULL;

;
ALTER TABLE `whitelist_ip` ADD COLUMN `granted_by_username` varchar(255) NULL,
                           ADD COLUMN `expire_epoch` integer NULL,
                           ADD INDEX `whitelist_ip_ip_amw_index` (`ip`);

;

COMMIT;

