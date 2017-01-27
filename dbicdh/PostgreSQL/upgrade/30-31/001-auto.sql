-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/30/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "custom_formats" (
  "custom_formats_id" serial NOT NULL,
  "site_id" character varying(16),
  "format_name" character varying(255) NOT NULL,
  "format_description" text,
  "active" smallint DEFAULT 1,
  "bb_format" character varying(16) DEFAULT 'pdf' NOT NULL,
  "bb_epub_embed_fonts" smallint DEFAULT 1,
  "bb_bcor" integer DEFAULT 0 NOT NULL,
  "bb_beamercolortheme" character varying(255) DEFAULT 'dove' NOT NULL,
  "bb_beamertheme" character varying(255) DEFAULT 'default' NOT NULL,
  "bb_cover" smallint DEFAULT 1,
  "bb_crop_marks" smallint DEFAULT 0,
  "bb_crop_papersize" character varying(255) DEFAULT 'a4' NOT NULL,
  "bb_crop_paper_height" integer DEFAULT 0 NOT NULL,
  "bb_crop_paper_width" integer DEFAULT 0 NOT NULL,
  "bb_crop_paper_thickness" character varying(16) DEFAULT '0.10mm' NOT NULL,
  "bb_division" integer DEFAULT 12 NOT NULL,
  "bb_fontsize" integer DEFAULT 10 NOT NULL,
  "bb_headings" character varying(255) DEFAULT '0' NOT NULL,
  "bb_imposed" smallint DEFAULT 0,
  "bb_mainfont" character varying(255),
  "bb_sansfont" character varying(255),
  "bb_monofont" character varying(255),
  "bb_nocoverpage" smallint DEFAULT 0,
  "bb_notoc" smallint DEFAULT 0,
  "bb_opening" character varying(16) DEFAULT 'any' NOT NULL,
  "bb_papersize" character varying(255) DEFAULT 'generic' NOT NULL,
  "bb_paper_height" integer DEFAULT 0 NOT NULL,
  "bb_paper_width" integer DEFAULT 0 NOT NULL,
  "bb_schema" character varying(255) DEFAULT '2up' NOT NULL,
  "bb_signature" integer DEFAULT 0 NOT NULL,
  "bb_twoside" smallint DEFAULT 0,
  "bb_unbranded" smallint DEFAULT 0,
  PRIMARY KEY ("custom_formats_id")
);
CREATE INDEX "custom_formats_idx_site_id" on "custom_formats" ("site_id");

;
ALTER TABLE "custom_formats" ADD CONSTRAINT "custom_formats_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE bookbuilder_profile ADD COLUMN custom_formats_id integer;

;
CREATE INDEX bookbuilder_profile_idx_custom_formats_id on bookbuilder_profile (custom_formats_id);

;
ALTER TABLE bookbuilder_profile ADD CONSTRAINT bookbuilder_profile_fk_custom_formats_id FOREIGN KEY (custom_formats_id)
  REFERENCES custom_formats (custom_formats_id) ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

