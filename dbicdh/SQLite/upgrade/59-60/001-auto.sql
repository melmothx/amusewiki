-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/59/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/60/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "whitelist_ip" (
  "site_id" varchar(16) NOT NULL,
  "ip" varchar(64) NOT NULL,
  PRIMARY KEY ("site_id", "ip"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "whitelist_ip_idx_site_id" ON "whitelist_ip" ("site_id");

;

COMMIT;

