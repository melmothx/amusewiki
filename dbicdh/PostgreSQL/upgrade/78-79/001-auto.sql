-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/78/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/79/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "node" ADD COLUMN "canonical_title" character varying(255) DEFAULT '' NOT NULL;

;
ALTER TABLE "node" ADD COLUMN "last_updated_epoch" integer DEFAULT 0 NOT NULL;

;
ALTER TABLE "node" ADD COLUMN "last_updated_dt" timestamp;

;

COMMIT;

