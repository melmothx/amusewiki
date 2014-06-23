-- Convert schema 'sql/AmuseWikiFarm-Schema-0.15-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.16-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ALTER COLUMN id TYPE character varying(16);


COMMIT;

