-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/85/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "node_aggregation" (
  "node_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "aggregation_id")
);
CREATE INDEX "node_aggregation_idx_aggregation_id" on "node_aggregation" ("aggregation_id");
CREATE INDEX "node_aggregation_idx_node_id" on "node_aggregation" ("node_id");

;
CREATE TABLE "node_aggregation_series" (
  "node_id" integer NOT NULL,
  "aggregation_series_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "aggregation_series_id")
);
CREATE INDEX "node_aggregation_series_idx_aggregation_series_id" on "node_aggregation_series" ("aggregation_series_id");
CREATE INDEX "node_aggregation_series_idx_node_id" on "node_aggregation_series" ("node_id");

;
ALTER TABLE "node_aggregation" ADD CONSTRAINT "node_aggregation_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation" ADD CONSTRAINT "node_aggregation_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation_series" ADD CONSTRAINT "node_aggregation_series_fk_aggregation_series_id" FOREIGN KEY ("aggregation_series_id")
  REFERENCES "aggregation_series" ("aggregation_series_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_aggregation_series" ADD CONSTRAINT "node_aggregation_series_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;
