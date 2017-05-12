-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "muse_header" (
  "title_id" integer NOT NULL,
  "muse_header" character varying(255) NOT NULL,
  "muse_value" text,
  PRIMARY KEY ("title_id", "muse_header")
);
CREATE INDEX "muse_header_idx_title_id" on "muse_header" ("title_id");

;
ALTER TABLE "muse_header" ADD CONSTRAINT "muse_header_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

