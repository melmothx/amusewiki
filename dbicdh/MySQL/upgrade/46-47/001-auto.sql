-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/46/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_continuefootnotes smallint NULL DEFAULT 0,
                           ADD COLUMN bb_centerchapter smallint NULL DEFAULT 0,
                           ADD COLUMN bb_centersection smallint NULL DEFAULT 0;

;

COMMIT;

