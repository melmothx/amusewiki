-- Check the situation with:
--  SELECT table_name, column_name, character_set_name FROM information_schema.`COLUMNS`  WHERE table_schema = 'amuse';

-- Alter the db (IMPORTANT, otherwise when creating new tables the FK will fail).

-- ALTER DATABASE amuse CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- otherwise the conversion will abort:
set foreign_key_checks=0;

alter table job_file                              convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table title                                 convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table muse_header                           convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table roles                                 convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table legacy_link                           convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table custom_formats                        convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table include_path                          convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table column_comments                       convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table redirection                           convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table attachment                            convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table node_body                             convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table users                                 convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table table_comments                        convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table bulk_job                              convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table text_part                             convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table dbix_class_deploymenthandler_versions convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table site                                  convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table bookbuilder_session                   convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table whitelist_ip                          convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table mirror_info                           convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table bookbuilder_profile                   convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table amw_session                           convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table job                                   convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table site_options                          convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table text_internal_link                    convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table site_category_type                    convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table revision                              convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table included_file                         convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table category                              convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table vhost                                 convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table mirror_origin                         convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table monthly_archive                       convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table category_description                  convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table site_link                             convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table global_site_files                     convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table user_site                             convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table title_stat                            convert to character set utf8mb4 collate utf8mb4_unicode_ci;
alter table node                                  convert to character set utf8mb4 collate utf8mb4_unicode_ci;
set foreign_key_checks=1;

-- then set the client connection:
-- and the in dbic.yaml change:   mysql_enable_utf8mb4: 1 instead of mysql_enable_utf8: 1
-- and restart amw
