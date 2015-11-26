-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/4/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `job_file` (
  `filename` varchar(255) NOT NULL,
  `job_id` integer NOT NULL,
  INDEX `job_file_idx_job_id` (`job_id`),
  PRIMARY KEY (`filename`),
  CONSTRAINT `job_file_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

