-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/27/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `bulk_job` (
  `bulk_job_id` integer NOT NULL auto_increment,
  `task` varchar(32) NULL,
  `created` datetime NOT NULL,
  `completed` datetime NULL,
  `site_id` varchar(16) NOT NULL,
  `username` varchar(255) NULL,
  INDEX `bulk_job_idx_site_id` (`site_id`),
  PRIMARY KEY (`bulk_job_id`),
  CONSTRAINT `bulk_job_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE job ADD COLUMN bulk_job_id integer NULL,
                CHANGE COLUMN priority priority integer NOT NULL DEFAULT 10,
                ADD INDEX job_idx_bulk_job_id (bulk_job_id),
                ADD CONSTRAINT job_fk_bulk_job_id FOREIGN KEY (bulk_job_id) REFERENCES bulk_job (bulk_job_id) ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

