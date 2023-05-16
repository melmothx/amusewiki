-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/77/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/78/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "oai_pmh_record" (
  "oai_pmh_record_id" INTEGER PRIMARY KEY NOT NULL,
  "identifier" varchar(255) NOT NULL,
  "datestamp" datetime NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "custom_formats_id" integer,
  "metadata_type" varchar(32),
  "metadata_format" varchar(32),
  "deleted" integer(1) NOT NULL DEFAULT 0,
  "update_run" integer NOT NULL DEFAULT 0,
  FOREIGN KEY ("attachment_id") REFERENCES "attachment"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("custom_formats_id") REFERENCES "custom_formats"("custom_formats_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

;
CREATE INDEX "oai_pmh_record_idx_attachment_id" ON "oai_pmh_record" ("attachment_id");

;
CREATE INDEX "oai_pmh_record_idx_custom_formats_id" ON "oai_pmh_record" ("custom_formats_id");

;
CREATE INDEX "oai_pmh_record_idx_site_id" ON "oai_pmh_record" ("site_id");

;
CREATE INDEX "oai_pmh_record_idx_title_id" ON "oai_pmh_record" ("title_id");

;
CREATE UNIQUE INDEX "identifier_site_id_unique" ON "oai_pmh_record" ("identifier", "site_id");

;
CREATE TABLE "oai_pmh_record_set" (
  "oai_pmh_record_id" integer NOT NULL,
  "oai_pmh_set_id" integer NOT NULL,
  PRIMARY KEY ("oai_pmh_record_id", "oai_pmh_set_id"),
  FOREIGN KEY ("oai_pmh_record_id") REFERENCES "oai_pmh_record"("oai_pmh_record_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("oai_pmh_set_id") REFERENCES "oai_pmh_set"("oai_pmh_set_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_record_id" ON "oai_pmh_record_set" ("oai_pmh_record_id");

;
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_set_id" ON "oai_pmh_record_set" ("oai_pmh_set_id");

;
CREATE TABLE "oai_pmh_set" (
  "oai_pmh_set_id" INTEGER PRIMARY KEY NOT NULL,
  "set_spec" varchar(255) NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "set_name" text,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "oai_pmh_set_idx_site_id" ON "oai_pmh_set" ("site_id");

;
CREATE UNIQUE INDEX "set_spec_site_id_unique" ON "oai_pmh_set" ("set_spec", "site_id");

;

COMMIT;

