-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/42/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_nobold smallint NULL DEFAULT 0,
                           ADD COLUMN bb_secondary_footnotes_alpha smallint NULL DEFAULT 0;

;

COMMIT;

