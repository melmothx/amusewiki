-- Convert schema 'sql/AmuseWikiFarm-Schema-0.05-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.06-SQLite.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN bb_page_limit integer NOT NULL DEFAULT 1000;


COMMIT;

