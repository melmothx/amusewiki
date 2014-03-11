-- Convert schema 'sql/AmuseWikiFarm-Schema-0.03-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.04-PostgreSQL.sql':;

BEGIN;

ALTER TABLE category ADD COLUMN text_count integer DEFAULT 0 NOT NULL;


COMMIT;

