-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/17/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title_stat DROP COLUMN notes,
                       ADD COLUMN user_agent text NULL,
                       ADD COLUMN type text NULL;

;

COMMIT;

