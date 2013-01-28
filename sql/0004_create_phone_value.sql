CREATE TABLE phone_value(
  id serial not null PRIMARY KEY,
  phone_key_id integer not null unique,
  phone_value VARCHAR(2048) not null,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP,
  foreign key (phone_key_id) references phone_key (id)
);

CREATE TRIGGER phone_value_timestamp BEFORE INSERT OR UPDATE ON phone_value
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
