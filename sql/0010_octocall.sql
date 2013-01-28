BEGIN;
CREATE TABLE octocall(
  id serial not null PRIMARY KEY,
  account_id integer not null,
  name varchar(128) NOT NULL,
  greeting varchar(512) NOT NULL,
  status varchar(30) NOT NULL,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (account_id) references account (id)
);

CREATE TRIGGER octocall_timestamp BEFORE INSERT OR UPDATE ON octocall
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

GRANT SELECT ON TABLE octocall TO kevin;
GRANT INSERT ON TABLE octocall TO kevin;
GRANT UPDATE ON TABLE octocall TO kevin;
GRANT DELETE ON TABLE octocall TO kevin;

GRANT USAGE, SELECT ON SEQUENCE octocall_id_seq TO kevin;
COMMIT;
