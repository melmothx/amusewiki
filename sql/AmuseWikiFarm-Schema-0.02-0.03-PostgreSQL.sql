-- Convert schema 'sql/AmuseWikiFarm-Schema-0.02-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.03-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN theme character varying(32) DEFAULT '' NOT NULL;


COMMIT;

