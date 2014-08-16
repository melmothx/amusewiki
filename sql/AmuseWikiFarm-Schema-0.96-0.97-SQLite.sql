-- Convert schema 'sql/AmuseWikiFarm-Schema-0.96-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.97-SQLite.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN logo_with_sitename integer(1) NOT NULL DEFAULT 0;


COMMIT;

