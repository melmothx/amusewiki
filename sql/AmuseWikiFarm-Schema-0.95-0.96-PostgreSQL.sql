-- Convert schema 'sql/AmuseWikiFarm-Schema-0.95-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.96-PostgreSQL.sql':;

BEGIN;

ALTER TABLE attachment ALTER COLUMN f_archive_rel_path TYPE character varying(32);

ALTER TABLE attachment ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE category ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE job ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE redirection ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE revision ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE title ALTER COLUMN f_archive_rel_path TYPE character varying(32);

ALTER TABLE title ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE user_site ALTER COLUMN site_id TYPE character varying(16);

ALTER TABLE vhost ALTER COLUMN site_id TYPE character varying(16);


COMMIT;

