-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/24/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `bookbuilder_profile` (
  `bookbuilder_profile_id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `profile_name` varchar(255) NOT NULL,
  `profile_data` text NOT NULL,
  INDEX `bookbuilder_profile_idx_user_id` (`user_id`),
  PRIMARY KEY (`bookbuilder_profile_id`),
  CONSTRAINT `bookbuilder_profile_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

