-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/65/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/66/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "custom_formats" ALTER COLUMN "bb_beamercolortheme" TYPE character varying(32);

;
ALTER TABLE "custom_formats" ALTER COLUMN "bb_beamertheme" TYPE character varying(32);

;
ALTER TABLE "custom_formats" ALTER COLUMN "bb_crop_papersize" TYPE character varying(32);

;
ALTER TABLE "custom_formats" ALTER COLUMN "bb_headings" TYPE character varying(64);

;
ALTER TABLE "custom_formats" ALTER COLUMN "bb_papersize" TYPE character varying(32);

;
ALTER TABLE "custom_formats" ALTER COLUMN "bb_schema" TYPE character varying(64);

;

COMMIT;

