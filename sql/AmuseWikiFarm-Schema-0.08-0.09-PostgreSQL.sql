-- Convert schema 'sql/AmuseWikiFarm-Schema-0.08-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.09-PostgreSQL.sql':;

BEGIN;

CREATE TABLE "role" (
  "id" serial NOT NULL,
  "role" character varying(128),
  PRIMARY KEY ("id"),
  CONSTRAINT "role_unique" UNIQUE ("role")
);

CREATE TABLE "user" (
  "id" serial NOT NULL,
  "username" character varying(128) NOT NULL,
  "password" character varying(255) NOT NULL,
  "email" character varying(255),
  "active" integer DEFAULT 1 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "username_unique" UNIQUE ("username")
);

CREATE TABLE "user_site" (
  "user_id" integer NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("user_id", "site_id")
);
CREATE INDEX "user_site_idx_site_id" on "user_site" ("site_id");
CREATE INDEX "user_site_idx_user_id" on "user_site" ("user_id");

ALTER TABLE "user_site" ADD CONSTRAINT "user_site_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE cascade ON UPDATE cascade DEFERRABLE;

ALTER TABLE "user_site" ADD CONSTRAINT "user_site_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE cascade ON UPDATE cascade DEFERRABLE;

ALTER TABLE user_role DROP CONSTRAINT user_role_fk_role_id;

ALTER TABLE user_role DROP CONSTRAINT user_role_fk_user_id;

ALTER TABLE user_role ADD CONSTRAINT user_role_fk_role_id FOREIGN KEY (role_id)
  REFERENCES role (id) ON DELETE cascade ON UPDATE cascade DEFERRABLE;

ALTER TABLE user_role ADD CONSTRAINT user_role_fk_user_id FOREIGN KEY (user_id)
  REFERENCES user (id) ON DELETE cascade ON UPDATE cascade DEFERRABLE;

DROP TABLE roles CASCADE;

DROP TABLE users CASCADE;


COMMIT;

