-- Convert schema 'sql/AmuseWikiFarm-Schema-0.11-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.12-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site DROP COLUMN mail;

ALTER TABLE site ADD COLUMN mail_notify character varying(255);

ALTER TABLE site ADD COLUMN mail_from character varying(255);


COMMIT;

