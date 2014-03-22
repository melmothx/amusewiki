-- Convert schema 'sql/AmuseWikiFarm-Schema-0.05-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.06-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN bb_page_limit integer DEFAULT 1000 NOT NULL;


COMMIT;

