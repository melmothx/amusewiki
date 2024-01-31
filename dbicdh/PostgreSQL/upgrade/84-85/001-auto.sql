-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/85/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "aggregation" ADD COLUMN "comment_muse" text;

;
ALTER TABLE "aggregation" ADD COLUMN "comment_html" text;

;
ALTER TABLE "aggregation_series" ADD COLUMN "comment_muse" text;

;
ALTER TABLE "aggregation_series" ADD COLUMN "comment_html" text;

;
ALTER TABLE "bookcover_token" ADD COLUMN "sorting_pos" integer DEFAULT 0 NOT NULL;

;

COMMIT;

