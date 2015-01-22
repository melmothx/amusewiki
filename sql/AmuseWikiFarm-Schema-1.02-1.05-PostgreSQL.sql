-- Convert schema 'sql/AmuseWikiFarm-Schema-1.02-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-1.05-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN opening character varying(16) DEFAULT 'any' NOT NULL;


COMMIT;

