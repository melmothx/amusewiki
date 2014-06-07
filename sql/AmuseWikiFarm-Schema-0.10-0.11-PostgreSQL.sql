-- Convert schema 'sql/AmuseWikiFarm-Schema-0.10-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.11-PostgreSQL.sql':;

BEGIN;

ALTER TABLE revision DROP CONSTRAINT ;

ALTER TABLE revision DROP COLUMN user_id;


COMMIT;

