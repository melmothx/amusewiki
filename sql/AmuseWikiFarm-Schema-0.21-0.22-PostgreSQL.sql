-- Convert schema 'sql/AmuseWikiFarm-Schema-0.21-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.22-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ALTER COLUMN sitegroup SET NOT NULL;

ALTER TABLE site ALTER COLUMN sitegroup SET DEFAULT '';

ALTER TABLE site ALTER COLUMN multilanguage TYPE character varying(255);

ALTER TABLE site ALTER COLUMN multilanguage SET DEFAULT '';

ALTER TABLE title ALTER COLUMN uid SET NOT NULL;

ALTER TABLE title ALTER COLUMN uid SET DEFAULT '';


COMMIT;

