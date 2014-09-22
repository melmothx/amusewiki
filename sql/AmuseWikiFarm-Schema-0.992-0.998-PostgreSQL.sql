-- Convert schema 'sql/AmuseWikiFarm-Schema-0.992-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.998-PostgreSQL.sql':;

BEGIN;

ALTER TABLE site ADD COLUMN secure_site integer DEFAULT 0 NOT NULL;

ALTER TABLE site ALTER COLUMN canonical DROP DEFAULT;

ALTER TABLE site ADD CONSTRAINT canonical_unique UNIQUE (canonical);


COMMIT;

