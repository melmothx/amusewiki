-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/87/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/88/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `node` ADD INDEX `node_site_id_sorting_pos_uri_index` (`site_id`, `sorting_pos`, `uri`);

;

COMMIT;

