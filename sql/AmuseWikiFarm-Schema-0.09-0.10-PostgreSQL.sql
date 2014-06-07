-- Convert schema 'sql/AmuseWikiFarm-Schema-0.09-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.10-PostgreSQL.sql':;

BEGIN;

ALTER TABLE revision ADD COLUMN message text;


COMMIT;

