-- Convert schema 'sql/AmuseWikiFarm-Schema-0.09-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.10-SQLite.sql':;

BEGIN;

ALTER TABLE revision ADD COLUMN message text;


COMMIT;

