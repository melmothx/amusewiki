-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/10/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN sitegroup_label,
                 DROP COLUMN catalog_label,
                 DROP COLUMN specials_label,
                 ADD COLUMN active integer(1) NOT NULL DEFAULT 1;

;

COMMIT;

