-- Convert schema 'sql/AmuseWikiFarm-Schema-0.97-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.992-SQLite.sql':;

BEGIN;

ALTER TABLE "site" ADD COLUMN "cgit_integration" integer(1) NOT NULL DEFAULT 0;


COMMIT;

