-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "site" ALTER COLUMN "cgit_integration" SET DEFAULT 0;

;
ALTER TABLE "users" ADD COLUMN "api_access_token" text;

;
ALTER TABLE "users" ADD COLUMN "api_access_created" timestamp;

;
ALTER TABLE "whitelist_ip" ADD COLUMN "granted_by_username" character varying(255);

;
ALTER TABLE "whitelist_ip" ADD COLUMN "expire_epoch" integer;

;
CREATE INDEX "whitelist_ip_ip_amw_index" on "whitelist_ip" ("ip");

;

COMMIT;

