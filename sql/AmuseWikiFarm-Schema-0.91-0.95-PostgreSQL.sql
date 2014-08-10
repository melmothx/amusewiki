-- Convert schema 'sql/AmuseWikiFarm-Schema-0.91-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.95-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN nocoverpage integer DEFAULT 0 NOT NULL;


COMMIT;

