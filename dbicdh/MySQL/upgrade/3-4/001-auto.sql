-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/3/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN username varchar(255) NULL;

;
ALTER TABLE revision ADD COLUMN username varchar(255) NULL;

;

COMMIT;

