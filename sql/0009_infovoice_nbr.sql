BEGIN;
CREATE TABLE infovoice_nbr(
  id serial not null PRIMARY KEY,
  infovoice_id integer not null,
  number varchar(128) not null,
  num_calls integer not null,
  last_call timestamp not null default CURRENT_TIMESTAMP,
  CallSid varchar(256) unique,
  status varchar(30) not null,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (infovoice_id) references infovoice (id),
  unique (infovoice_id, number)
);

CREATE TRIGGER infovoice_nbr_timestamp BEFORE INSERT OR UPDATE ON infovoice_nbr
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

GRANT SELECT ON TABLE infovoice_nbr TO kevin;
GRANT INSERT ON TABLE infovoice_nbr TO kevin;
GRANT UPDATE ON TABLE infovoice_nbr TO kevin;
GRANT DELETE ON TABLE infovoice_nbr TO kevin;

GRANT USAGE, SELECT ON SEQUENCE infovoice_nbr_id_seq TO kevin;
COMMIT;
