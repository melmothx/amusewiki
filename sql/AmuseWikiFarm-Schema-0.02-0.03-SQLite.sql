-- Convert schema 'sql/AmuseWikiFarm-Schema-0.02-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.03-SQLite.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN theme varchar(32) NOT NULL DEFAULT '';


COMMIT;

