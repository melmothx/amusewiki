-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/24/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "bookbuilder_profile" (
  "bookbuilder_profile_id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "profile_name" character varying(255) NOT NULL,
  "profile_data" text NOT NULL,
  PRIMARY KEY ("bookbuilder_profile_id")
);
CREATE INDEX "bookbuilder_profile_idx_user_id" on "bookbuilder_profile" ("user_id");

;
ALTER TABLE "bookbuilder_profile" ADD CONSTRAINT "bookbuilder_profile_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

