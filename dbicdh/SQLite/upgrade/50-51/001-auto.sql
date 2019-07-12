-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/50/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE node (
  node_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  parent_node_id integer,
  FOREIGN KEY (parent_node_id) REFERENCES node(node_id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX node_idx_parent_node_id ON node (parent_node_id);

;
CREATE INDEX node_idx_site_id ON node (site_id);

;
CREATE UNIQUE INDEX site_id_uri_unique ON node (site_id, uri);

;
CREATE TABLE node_body (
  node_id integer NOT NULL,
  lang varchar(3) NOT NULL DEFAULT 'en',
  title_muse text,
  title_html text,
  body_muse text,
  body_html text,
  PRIMARY KEY (node_id, lang),
  FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX node_body_idx_node_id ON node_body (node_id);

;
CREATE TABLE node_category (
  node_id integer NOT NULL,
  category_id integer NOT NULL,
  PRIMARY KEY (node_id, category_id),
  FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX node_category_idx_category_id ON node_category (category_id);

;
CREATE INDEX node_category_idx_node_id ON node_category (node_id);

;
CREATE TABLE node_title (
  node_id integer NOT NULL,
  title_id integer NOT NULL,
  PRIMARY KEY (node_id, title_id),
  FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX node_title_idx_node_id ON node_title (node_id);

;
CREATE INDEX node_title_idx_title_id ON node_title (title_id);

;

COMMIT;

