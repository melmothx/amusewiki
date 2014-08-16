-- Convert schema 'sql/AmuseWikiFarm-Schema-0.96-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.97-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN logo_with_sitename integer DEFAULT 0 NOT NULL;


COMMIT;

