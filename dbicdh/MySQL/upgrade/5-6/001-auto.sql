-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/5/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job_file ADD COLUMN slot varchar(255) NOT NULL DEFAULT '';

;

COMMIT;

