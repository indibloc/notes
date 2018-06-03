BEGIN TRANSACTION;
DROP TABLE IF EXISTS `prod_spec_attr`;
CREATE TABLE IF NOT EXISTS `prod_spec_attr` (
	`attr_uuid`	TEXT,
	`prod_spec_uuid`	TEXT,
	`attr_taxonomy_urn`	TEXT,
	`attr_val`	TEXT,
	`title_i18n_id`	TEXT,
	`note_i18n_id`	TEXT,
	PRIMARY KEY(`attr_uuid`)
);
DROP TABLE IF EXISTS `key_tag`;
CREATE TABLE IF NOT EXISTS `key_tag` (
	`key_uuid`	TEXT NOT NULL,
	`value`	TEXT,
	PRIMARY KEY(`key_uuid`)
);
DROP TABLE IF EXISTS `i18n_dict`;
CREATE TABLE IF NOT EXISTS `i18n_dict` (
	`key_i18n_id`	TEXT,
	`iso_lang`	TEXT,
	`txt_val`	TEXT
);
DROP TABLE IF EXISTS `prod_specs`;
CREATE TABLE IF NOT EXISTS `prod_specs` (
	`uuid`	TEXT NOT NULL,
	`taxonomy_urn`	TEXT,
	`url`	TEXT,
	`title_i18n_id`	TEXT,
	`notes_i18n_id`	TEXT,
	`pic_url`	TEXT,
	`geo_fenced_latlong`	TEXT,
	`publisher_email`	TEXT,
	`published_tmstamp`	TEXT,
	`valid_from_tmstamp`	TEXT,
	`valid_till_tmstamp`	TEXT,
	PRIMARY KEY(`uuid`)
);
DROP TABLE IF EXISTS `attachements`;
CREATE TABLE IF NOT EXISTS `attachements` (
	`uuid`	TEXT NOT NULL UNIQUE,
	`key_ref_id`	TEXT NOT NULL,
	`title_i18n_id`	TEXT,
	`uri`	TEXT NOT NULL
);
COMMIT;
