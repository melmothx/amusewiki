-- Convert schema 'sql/AmuseWikiFarm-Schema-0.01-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.02-SQLite.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN zip integer NOT NULL DEFAULT 1;


COMMIT;

