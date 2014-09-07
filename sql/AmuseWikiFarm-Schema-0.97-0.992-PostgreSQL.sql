-- Convert schema 'sql/AmuseWikiFarm-Schema-0.97-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.992-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN cgit_integration integer DEFAULT 0 NOT NULL;


COMMIT;

