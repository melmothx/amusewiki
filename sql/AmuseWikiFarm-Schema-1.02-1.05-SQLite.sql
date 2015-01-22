-- Convert schema 'sql/AmuseWikiFarm-Schema-1.02-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-1.05-SQLite.sql':;

BEGIN;

ALTER TABLE "site" ADD COLUMN "opening" varchar(16) NOT NULL DEFAULT 'any';


COMMIT;

