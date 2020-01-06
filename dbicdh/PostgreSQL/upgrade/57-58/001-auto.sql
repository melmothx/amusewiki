-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/57/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/58/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN parent character varying(255);

;

COMMIT;

