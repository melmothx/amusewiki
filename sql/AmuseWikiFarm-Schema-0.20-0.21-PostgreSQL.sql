-- Convert schema 'sql/AmuseWikiFarm-Schema-0.20-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.21-PostgreSQL.sql':;

BEGIN;

ALTER TABLE title ALTER COLUMN attach TYPE text;


COMMIT;

