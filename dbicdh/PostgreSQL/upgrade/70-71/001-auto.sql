-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/70/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/71/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "mirror_info" (
  "mirror_info_id" serial NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "mirror_origin_id" integer,
  "site_id" character varying(16) NOT NULL,
  "checksum" character varying(128),
  "download_source" text,
  "download_destination" text,
  "mirror_exception" character varying(32) DEFAULT '' NOT NULL,
  "last_updated" timestamp,
  PRIMARY KEY ("mirror_info_id"),
  CONSTRAINT "attachment_id_unique" UNIQUE ("attachment_id"),
  CONSTRAINT "title_id_unique" UNIQUE ("title_id")
);
CREATE INDEX "mirror_info_idx_attachment_id" on "mirror_info" ("attachment_id");
CREATE INDEX "mirror_info_idx_mirror_origin_id" on "mirror_info" ("mirror_origin_id");
CREATE INDEX "mirror_info_idx_site_id" on "mirror_info" ("site_id");
CREATE INDEX "mirror_info_idx_title_id" on "mirror_info" ("title_id");

;
CREATE TABLE "mirror_origin" (
  "mirror_origin_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "remote_domain" character varying(255) NOT NULL,
  "remote_path" character varying(255) NOT NULL,
  "active" smallint DEFAULT 0 NOT NULL,
  "status_message" text,
  "last_downloaded" timestamp,
  PRIMARY KEY ("mirror_origin_id")
);
CREATE INDEX "mirror_origin_idx_site_id" on "mirror_origin" ("site_id");

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_mirror_origin_id" FOREIGN KEY ("mirror_origin_id")
  REFERENCES "mirror_origin" ("mirror_origin_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_origin" ADD CONSTRAINT "mirror_origin_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "bulk_job" ADD COLUMN "payload" text;

;
ALTER TABLE "bulk_job" ADD COLUMN "produced" character varying(255);

;

COMMIT;

