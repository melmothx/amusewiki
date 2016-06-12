-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/18/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN cover character varying(255) DEFAULT '' NOT NULL;

;
ALTER TABLE title ADD COLUMN teaser text DEFAULT '' NOT NULL;

;

COMMIT;

