-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Oct 28 14:24:36 2016
-- 

;
BEGIN TRANSACTION;
--
-- Table: "dbix_class_deploymenthandler_versions"
--
CREATE TABLE "dbix_class_deploymenthandler_versions" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "version" varchar(50) NOT NULL,
  "ddl" text,
  "upgrade_sql" text
);
CREATE UNIQUE INDEX "dbix_class_deploymenthandler_versions_version" ON "dbix_class_deploymenthandler_versions" ("version");
COMMIT;
