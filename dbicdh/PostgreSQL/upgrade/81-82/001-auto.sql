-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation" (
  "aggregation_id" serial NOT NULL,
  "aggregation_series_id" integer,
  "aggregation_uri" character varying(255) NOT NULL,
  "aggregation_name" character varying(255),
  "publication_date" character varying(255),
  "publication_date_year" integer,
  "publication_date_month" integer,
  "publication_date_day" integer,
  "issue" character varying(255),
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "publication_place" character varying(255),
  "publisher" character varying(255),
  "isbn" character varying(32),
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("aggregation_id"),
  CONSTRAINT "aggregation_uri_site_id_unique" UNIQUE ("aggregation_uri", "site_id")
);
CREATE INDEX "aggregation_idx_aggregation_series_id" on "aggregation" ("aggregation_series_id");
CREATE INDEX "aggregation_idx_site_id" on "aggregation" ("site_id");
CREATE INDEX "aggregation_uri_amw_index" on "aggregation" ("aggregation_uri");

;
CREATE TABLE "aggregation_annotation" (
  "annotation_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  "annotation_value" text,
  PRIMARY KEY ("annotation_id", "aggregation_id")
);
CREATE INDEX "aggregation_annotation_idx_aggregation_id" on "aggregation_annotation" ("aggregation_id");
CREATE INDEX "aggregation_annotation_idx_annotation_id" on "aggregation_annotation" ("annotation_id");

;
CREATE TABLE "aggregation_series" (
  "aggregation_series_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "aggregation_series_uri" character varying(255) NOT NULL,
  "aggregation_series_name" character varying(255) NOT NULL,
  "publisher" character varying(255),
  "publication_place" character varying(255),
  PRIMARY KEY ("aggregation_series_id"),
  CONSTRAINT "aggregation_series_uri_site_id_unique" UNIQUE ("aggregation_series_uri", "site_id")
);
CREATE INDEX "aggregation_series_idx_site_id" on "aggregation_series" ("site_id");

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
CREATE TABLE "node_aggregation" (
  "node_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "aggregation_id")
);
CREATE INDEX "node_aggregation_idx_aggregation_id" on "node_aggregation" ("aggregation_id");
CREATE INDEX "node_aggregation_idx_node_id" on "node_aggregation" ("node_id");

;
CREATE TABLE "node_aggregation_series" (
  "node_id" integer NOT NULL,
  "aggregation_series_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "aggregation_series_id")
);
CREATE INDEX "node_aggregation_series_idx_aggregation_series_id" on "node_aggregation_series" ("aggregation_series_id");
CREATE INDEX "node_aggregation_series_idx_node_id" on "node_aggregation_series" ("node_id");

;
ALTER TABLE "aggregation" ADD CONSTRAINT "aggregation_fk_aggregation_series_id" FOREIGN KEY ("aggregation_series_id")
  REFERENCES "aggregation_series" ("aggregation_series_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "aggregation" ADD CONSTRAINT "aggregation_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "aggregation_annotation" ADD CONSTRAINT "aggregation_annotation_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "aggregation_annotation" ADD CONSTRAINT "aggregation_annotation_fk_annotation_id" FOREIGN KEY ("annotation_id")
  REFERENCES "annotation" ("annotation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "aggregation_series" ADD CONSTRAINT "aggregation_series_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "aggregation_title" ADD CONSTRAINT "aggregation_title_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation" ADD CONSTRAINT "node_aggregation_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation" ADD CONSTRAINT "node_aggregation_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation_series" ADD CONSTRAINT "node_aggregation_series_fk_aggregation_series_id" FOREIGN KEY ("aggregation_series_id")
  REFERENCES "aggregation_series" ("aggregation_series_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation_series" ADD CONSTRAINT "node_aggregation_series_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

