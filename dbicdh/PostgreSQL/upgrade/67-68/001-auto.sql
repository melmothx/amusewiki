-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/67/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/68/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "global_site_files" DROP CONSTRAINT "global_site_files_pkey";

;
ALTER TABLE "global_site_files" ADD PRIMARY KEY ("site_id", "file_name", "file_type");

;

COMMIT;

