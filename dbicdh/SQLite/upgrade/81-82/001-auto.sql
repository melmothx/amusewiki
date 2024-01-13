-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation" (
  "aggregation_id" INTEGER PRIMARY KEY NOT NULL,
  "aggregation_code" varchar(255) NOT NULL,
  "aggregation_uri" varchar(255) NOT NULL,
  "aggregation_name" varchar(255) NOT NULL,
  "series_number" varchar(255),
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "publication_place" varchar(255),
  "publication_date" varchar(255),
  "isbn" varchar(32),
  "publisher" varchar(255),
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_idx_site_id" ON "aggregation" ("site_id");

;
CREATE INDEX "aggregation_uri_amw_index" ON "aggregation" ("aggregation_uri");

;
CREATE INDEX "aggregation_code_amw_index" ON "aggregation" ("aggregation_code");

;
CREATE UNIQUE INDEX "aggregation_uri_site_id_unique" ON "aggregation" ("aggregation_uri", "site_id");

;
CREATE TABLE "aggregation_title" (
  "aggregation_id" integer NOT NULL,
  "title_uri" varchar(255) NOT NULL,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  PRIMARY KEY ("aggregation_id", "title_uri"),
  FOREIGN KEY ("aggregation_id") REFERENCES "aggregation"("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_title_idx_aggregation_id" ON "aggregation_title" ("aggregation_id");

;
CREATE INDEX "aggregation_title_uri_amw_index" ON "aggregation_title" ("title_uri");

;

COMMIT;

