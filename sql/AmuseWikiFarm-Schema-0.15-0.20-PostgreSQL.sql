-- Convert schema 'sql/AmuseWikiFarm-Schema-0.15-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.20-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN sitegroup_label character varying(255);

ALTER TABLE site ADD COLUMN catalog_label character varying(255);

ALTER TABLE site ADD COLUMN specials_label character varying(255);

ALTER TABLE site ADD COLUMN multilanguage integer DEFAULT 0 NOT NULL;

ALTER TABLE site ALTER COLUMN id TYPE character varying(16);

ALTER TABLE site ALTER COLUMN magic_question TYPE character varying(255);

ALTER TABLE site ALTER COLUMN magic_answer TYPE character varying(255);

ALTER TABLE site ALTER COLUMN fixed_category_list TYPE character varying(255);

ALTER TABLE site ALTER COLUMN logo TYPE character varying(255);

ALTER TABLE site ALTER COLUMN sitegroup TYPE character varying(255);

ALTER TABLE site ALTER COLUMN ttdir TYPE character varying(255);


COMMIT;

