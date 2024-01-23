-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation" (
  "aggregation_id" INTEGER PRIMARY KEY NOT NULL,
  "aggregation_series_id" integer,
  "aggregation_uri" varchar(255) NOT NULL,
  "aggregation_name" varchar(255),
  "publication_date" varchar(255),
  "publication_date_year" integer,
  "publication_date_month" integer,
  "publication_date_day" integer,
  "issue" varchar(255),
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "publication_place" varchar(255),
  "publisher" varchar(255),
  "isbn" varchar(32),
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("aggregation_series_id") REFERENCES "aggregation_series"("aggregation_series_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_idx_aggregation_series_id" ON "aggregation" ("aggregation_series_id");

;
CREATE INDEX "aggregation_idx_site_id" ON "aggregation" ("site_id");

;
CREATE INDEX "aggregation_uri_amw_index" ON "aggregation" ("aggregation_uri");

;
CREATE UNIQUE INDEX "aggregation_uri_site_id_unique" ON "aggregation" ("aggregation_uri", "site_id");

;
CREATE TABLE "aggregation_annotation" (
  "annotation_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  "annotation_value" text,
  PRIMARY KEY ("annotation_id", "aggregation_id"),
  FOREIGN KEY ("aggregation_id") REFERENCES "aggregation"("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("annotation_id") REFERENCES "annotation"("annotation_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_annotation_idx_aggregation_id" ON "aggregation_annotation" ("aggregation_id");

;
CREATE INDEX "aggregation_annotation_idx_annotation_id" ON "aggregation_annotation" ("annotation_id");

;
CREATE TABLE "aggregation_series" (
  "aggregation_series_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "aggregation_series_uri" varchar(255) NOT NULL,
  "aggregation_series_name" varchar(255) NOT NULL,
  "publisher" varchar(255),
  "publication_place" varchar(255),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_series_idx_site_id" ON "aggregation_series" ("site_id");

;
CREATE UNIQUE INDEX "aggregation_series_uri_site_id_unique" ON "aggregation_series" ("aggregation_series_uri", "site_id");

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
CREATE TABLE "node_aggregation" (
  "node_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "aggregation_id"),
  FOREIGN KEY ("aggregation_id") REFERENCES "aggregation"("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("node_id") REFERENCES "node"("node_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "node_aggregation_idx_aggregation_id" ON "node_aggregation" ("aggregation_id");

;
CREATE INDEX "node_aggregation_idx_node_id" ON "node_aggregation" ("node_id");

;
CREATE TABLE "node_aggregation_series" (
  "node_id" integer NOT NULL,
  "aggregation_series_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "aggregation_series_id"),
  FOREIGN KEY ("aggregation_series_id") REFERENCES "aggregation_series"("aggregation_series_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("node_id") REFERENCES "node"("node_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "node_aggregation_series_idx_aggregation_series_id" ON "node_aggregation_series" ("aggregation_series_id");

;
CREATE INDEX "node_aggregation_series_idx_node_id" ON "node_aggregation_series" ("node_id");

;

COMMIT;

