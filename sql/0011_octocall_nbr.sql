BEGIN;
CREATE TABLE octocall_nbr(
  id serial not null PRIMARY KEY,
  octocall_id integer not null,
  number varchar(128) not null,
  num_calls integer not null,
  last_call timestamp default CURRENT_TIMESTAMP,
  call_status varchar(30) not null,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (octocall_id) references octocall (id),
  unique (octocall_id, number)
);

CREATE TRIGGER octocall_nbr_timestamp BEFORE INSERT OR UPDATE ON octocall_nbr
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

GRANT SELECT ON TABLE octocall_nbr TO kevin;
GRANT INSERT ON TABLE octocall_nbr TO kevin;
GRANT UPDATE ON TABLE octocall_nbr TO kevin;
GRANT DELETE ON TABLE octocall_nbr TO kevin;

GRANT USAGE, SELECT ON SEQUENCE octocall_nbr_id_seq TO kevin;
COMMIT;
