-- Convert schema 'sql/AmuseWikiFarm-Schema-0.91-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.95-SQLite.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN nocoverpage integer(1) NOT NULL DEFAULT 0;


COMMIT;

