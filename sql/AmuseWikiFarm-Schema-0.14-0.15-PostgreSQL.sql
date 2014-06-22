-- Convert schema 'sql/AmuseWikiFarm-Schema-0.14-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.15-PostgreSQL.sql':;

BEGIN;

ALTER TABLE user ALTER COLUMN username TYPE character varying(255);


COMMIT;

