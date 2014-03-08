-- Convert schema 'sql/AmuseWikiFarm-Schema-0.01-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.02-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN zip integer DEFAULT 1 NOT NULL;


COMMIT;

