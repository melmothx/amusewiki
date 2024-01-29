-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "bookcover" (
  "bookcover_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title" varchar(255) NOT NULL DEFAULT '',
  "coverheight" integer NOT NULL DEFAULT 210,
  "coverwidth" integer NOT NULL DEFAULT 148,
  "spinewidth" integer NOT NULL DEFAULT 0,
  "flapwidth" integer NOT NULL DEFAULT 0,
  "wrapwidth" integer NOT NULL DEFAULT 0,
  "bleedwidth" integer NOT NULL DEFAULT 10,
  "marklength" integer NOT NULL DEFAULT 5,
  "foldingmargin" smallint NOT NULL DEFAULT 0,
  "created" datetime NOT NULL,
  "compiled" datetime,
  "zip_path" varchar(255),
  "pdf_path" varchar(255),
  "template" varchar(64),
  "font_name" varchar(255),
  "language_code" varchar(8),
  "comments" text,
  "session_id" varchar(255),
  "user_id" integer,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "bookcover_idx_site_id" ON "bookcover" ("site_id");

;
CREATE INDEX "bookcover_idx_user_id" ON "bookcover" ("user_id");

;
CREATE TABLE "bookcover_token" (
  "bookcover_id" varchar(16) NOT NULL,
  "token_name" varchar(255) NOT NULL,
  "token_value" text,
  PRIMARY KEY ("bookcover_id", "token_name"),
  FOREIGN KEY ("bookcover_id") REFERENCES "bookcover"("bookcover_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "bookcover_token_idx_bookcover_id" ON "bookcover_token" ("bookcover_id");

;

COMMIT;

