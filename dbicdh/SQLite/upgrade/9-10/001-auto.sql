-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/9/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN text_structure text NOT NULL DEFAULT '';

;

COMMIT;

