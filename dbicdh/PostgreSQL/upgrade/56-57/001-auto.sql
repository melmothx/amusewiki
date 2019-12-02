-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/56/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/57/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_code character varying(8);

;

COMMIT;

