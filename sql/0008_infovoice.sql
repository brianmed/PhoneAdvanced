BEGIN;
CREATE TABLE infovoice(
  id serial not null PRIMARY KEY,
  account_id integer not null,
  name varchar(128) NOT NULL,
  twiml TEXT NOT NULL,
  status varchar(30) not null,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (account_id) references account (id)
);

CREATE TRIGGER infovoice_timestamp BEFORE INSERT OR UPDATE ON infovoice
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

GRANT SELECT ON TABLE infovoice TO kevin;
GRANT INSERT ON TABLE infovoice TO kevin;
GRANT UPDATE ON TABLE infovoice TO kevin;
GRANT DELETE ON TABLE infovoice TO kevin;

GRANT USAGE, SELECT ON SEQUENCE infovoice_id_seq TO kevin;
COMMIT;
