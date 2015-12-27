-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/10/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN sitegroup_label;

;
ALTER TABLE site DROP COLUMN catalog_label;

;
ALTER TABLE site DROP COLUMN specials_label;

;
ALTER TABLE site ADD COLUMN active smallint DEFAULT 1 NOT NULL;

;

COMMIT;

