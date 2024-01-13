-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation" (
  "aggregation_id" serial NOT NULL,
  "aggregation_code" character varying(255) NOT NULL,
  "aggregation_uri" character varying(255) NOT NULL,
  "aggregation_name" character varying(255) NOT NULL,
  "series_number" character varying(255),
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "publication_place" character varying(255),
  "publication_date" character varying(255),
  "isbn" character varying(32),
  "publisher" character varying(255),
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("aggregation_id"),
  CONSTRAINT "aggregation_uri_site_id_unique" UNIQUE ("aggregation_uri", "site_id")
);
CREATE INDEX "aggregation_idx_site_id" on "aggregation" ("site_id");
CREATE INDEX "aggregation_uri_amw_index" on "aggregation" ("aggregation_uri");
CREATE INDEX "aggregation_code_amw_index" on "aggregation" ("aggregation_code");

;
CREATE TABLE "aggregation_title" (
  "aggregation_id" integer NOT NULL,
  "title_uri" character varying(255) NOT NULL,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("aggregation_id", "title_uri")
);
CREATE INDEX "aggregation_title_idx_aggregation_id" on "aggregation_title" ("aggregation_id");
CREATE INDEX "aggregation_title_uri_amw_index" on "aggregation_title" ("title_uri");

;
ALTER TABLE "aggregation" ADD CONSTRAINT "aggregation_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "aggregation_title" ADD CONSTRAINT "aggregation_title_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

