-- Convert schema 'sql/AmuseWikiFarm-Schema-0.03-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.04-SQLite.sql':;

BEGIN;

ALTER TABLE category ADD COLUMN text_count integer NOT NULL DEFAULT 0;


COMMIT;

