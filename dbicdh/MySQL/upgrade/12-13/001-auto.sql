-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/12/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `column_comments` (
  `table_name` varchar(255) NULL,
  `column_name` varchar(255) NULL,
  `comment_text` text NULL
);

;
CREATE TABLE `table_comments` (
  `table_name` varchar(255) NULL,
  `comment_text` text NULL
);

;
SET foreign_key_checks=1;

;

COMMIT;

