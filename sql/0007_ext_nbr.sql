BEGIN;
CREATE TABLE ext_nbr(
  id serial not null PRIMARY KEY,
  account_id integer not null unique,
  number VARCHAR(128) NOT NULL UNIQUE,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (account_id) references account (id)
);

CREATE TRIGGER ext_nbr_timestamp BEFORE INSERT OR UPDATE ON ext_nbr
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

GRANT SELECT ON TABLE ext_nbr TO kevin;
GRANT INSERT ON TABLE ext_nbr TO kevin;
GRANT UPDATE ON TABLE ext_nbr TO kevin;
GRANT DELETE ON TABLE ext_nbr TO kevin;

GRANT USAGE, SELECT ON SEQUENCE ext_nbr_id_seq TO kevin;
COMMIT;
