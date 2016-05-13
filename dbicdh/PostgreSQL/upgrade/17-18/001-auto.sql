-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/17/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title_stat DROP COLUMN notes;

;
ALTER TABLE title_stat ADD COLUMN user_agent text;

;
ALTER TABLE title_stat ADD COLUMN type text;

;

COMMIT;

