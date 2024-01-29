-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "bookcover" (
  "bookcover_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title" character varying(255) DEFAULT '' NOT NULL,
  "coverheight" integer DEFAULT 210 NOT NULL,
  "coverwidth" integer DEFAULT 148 NOT NULL,
  "spinewidth" integer DEFAULT 0 NOT NULL,
  "flapwidth" integer DEFAULT 0 NOT NULL,
  "wrapwidth" integer DEFAULT 0 NOT NULL,
  "bleedwidth" integer DEFAULT 10 NOT NULL,
  "marklength" integer DEFAULT 5 NOT NULL,
  "foldingmargin" smallint DEFAULT 0 NOT NULL,
  "created" timestamp NOT NULL,
  "compiled" timestamp,
  "zip_path" character varying(255),
  "pdf_path" character varying(255),
  "template" character varying(64),
  "font_name" character varying(255),
  "language_code" character varying(8),
  "comments" text,
  "session_id" character varying(255),
  "user_id" integer,
  PRIMARY KEY ("bookcover_id")
);
CREATE INDEX "bookcover_idx_site_id" on "bookcover" ("site_id");
CREATE INDEX "bookcover_idx_user_id" on "bookcover" ("user_id");

;
CREATE TABLE "bookcover_token" (
  "bookcover_id" character varying(16) NOT NULL,
  "token_name" character varying(255) NOT NULL,
  "token_value" text,
  PRIMARY KEY ("bookcover_id", "token_name")
);
CREATE INDEX "bookcover_token_idx_bookcover_id" on "bookcover_token" ("bookcover_id");

;
ALTER TABLE "bookcover" ADD CONSTRAINT "bookcover_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "bookcover" ADD CONSTRAINT "bookcover_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "bookcover_token" ADD CONSTRAINT "bookcover_token_fk_bookcover_id" FOREIGN KEY ("bookcover_id")
  REFERENCES "bookcover" ("bookcover_id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

