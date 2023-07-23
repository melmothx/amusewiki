-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/78/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/79/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE node ADD COLUMN canonical_title varchar(255) NOT NULL DEFAULT '';

;
ALTER TABLE node ADD COLUMN last_updated_epoch integer NOT NULL DEFAULT 0;

;
ALTER TABLE node ADD COLUMN last_updated_dt datetime;

;

COMMIT;

