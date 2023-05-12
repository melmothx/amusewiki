-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/77/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/78/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "oai_pmh_record" (
  "identifier" character varying(512) NOT NULL,
  "datestamp" timestamp,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "custom_formats_id" integer,
  "metadata_identifier" character varying(512),
  "metadata_type" character varying(32),
  "metadata_format" character varying(32),
  "deleted" smallint DEFAULT 0 NOT NULL,
  "update_run" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("identifier")
);
CREATE INDEX "oai_pmh_record_idx_attachment_id" on "oai_pmh_record" ("attachment_id");
CREATE INDEX "oai_pmh_record_idx_custom_formats_id" on "oai_pmh_record" ("custom_formats_id");
CREATE INDEX "oai_pmh_record_idx_site_id" on "oai_pmh_record" ("site_id");
CREATE INDEX "oai_pmh_record_idx_title_id" on "oai_pmh_record" ("title_id");

;
CREATE TABLE "oai_pmh_record_set" (
  "oai_pmh_record_id" character varying(512) NOT NULL,
  "oai_pmh_set_id" integer NOT NULL,
  PRIMARY KEY ("oai_pmh_record_id", "oai_pmh_set_id")
);
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_record_id" on "oai_pmh_record_set" ("oai_pmh_record_id");
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_set_id" on "oai_pmh_record_set" ("oai_pmh_set_id");

;
CREATE TABLE "oai_pmh_set" (
  "oai_pmh_set_id" serial NOT NULL,
  "set_spec" character varying(255) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "set_name" text,
  PRIMARY KEY ("oai_pmh_set_id"),
  CONSTRAINT "set_spec_site_id_unique" UNIQUE ("set_spec", "site_id")
);
CREATE INDEX "oai_pmh_set_idx_site_id" on "oai_pmh_set" ("site_id");

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_custom_formats_id" FOREIGN KEY ("custom_formats_id")
  REFERENCES "custom_formats" ("custom_formats_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record_set" ADD CONSTRAINT "oai_pmh_record_set_fk_oai_pmh_record_id" FOREIGN KEY ("oai_pmh_record_id")
  REFERENCES "oai_pmh_record" ("identifier") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record_set" ADD CONSTRAINT "oai_pmh_record_set_fk_oai_pmh_set_id" FOREIGN KEY ("oai_pmh_set_id")
  REFERENCES "oai_pmh_set" ("oai_pmh_set_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_set" ADD CONSTRAINT "oai_pmh_set_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

