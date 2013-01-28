CREATE TABLE phone_key(
  id serial not null PRIMARY KEY,
  phone_log_id integer not null,
  phone_key VARCHAR(128) not null,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (phone_log_id) references phone_log (id),
  unique (phone_log_id, phone_key)
);

CREATE TRIGGER phone_key_timestamp BEFORE INSERT OR UPDATE ON phone_key
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
