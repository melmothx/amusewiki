-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/59/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/60/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "whitelist_ip" (
  "site_id" character varying(16) NOT NULL,
  "ip" character varying(64) NOT NULL,
  PRIMARY KEY ("site_id", "ip")
);
CREATE INDEX "whitelist_ip_idx_site_id" on "whitelist_ip" ("site_id");

;
ALTER TABLE "whitelist_ip" ADD CONSTRAINT "whitelist_ip_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

