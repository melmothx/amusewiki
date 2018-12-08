-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/46/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_continuefootnotes smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_centerchapter smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_centersection smallint DEFAULT 0;

;

COMMIT;

