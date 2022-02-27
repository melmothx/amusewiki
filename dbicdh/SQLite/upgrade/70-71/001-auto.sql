-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/70/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/71/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "mirror_info" (
  "mirror_info_id" INTEGER PRIMARY KEY NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "mirror_origin_id" integer,
  "site_id" varchar(16) NOT NULL,
  "checksum" varchar(128),
  "download_source" text,
  "download_destination" text,
  "mirror_exception" varchar(32) NOT NULL DEFAULT '',
  "last_updated" datetime,
  FOREIGN KEY ("attachment_id") REFERENCES "attachment"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("mirror_origin_id") REFERENCES "mirror_origin"("mirror_origin_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "mirror_info_idx_attachment_id" ON "mirror_info" ("attachment_id");

;
CREATE INDEX "mirror_info_idx_mirror_origin_id" ON "mirror_info" ("mirror_origin_id");

;
CREATE INDEX "mirror_info_idx_site_id" ON "mirror_info" ("site_id");

;
CREATE INDEX "mirror_info_idx_title_id" ON "mirror_info" ("title_id");

;
CREATE UNIQUE INDEX "attachment_id_unique" ON "mirror_info" ("attachment_id");

;
CREATE UNIQUE INDEX "title_id_unique" ON "mirror_info" ("title_id");

;
CREATE TABLE "mirror_origin" (
  "mirror_origin_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "remote_domain" varchar(255) NOT NULL,
  "remote_path" varchar(255) NOT NULL,
  "active" integer(1) NOT NULL DEFAULT 0,
  "status_message" text,
  "last_downloaded" datetime,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "mirror_origin_idx_site_id" ON "mirror_origin" ("site_id");

;
ALTER TABLE bulk_job ADD COLUMN payload text;

;
ALTER TABLE bulk_job ADD COLUMN produced varchar(255);

;

COMMIT;

