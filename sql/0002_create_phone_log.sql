CREATE TABLE phone_log(
  id serial not null PRIMARY KEY,
  sub varchar(128) not null,
  caller varchar(60) not null,
  called varchar(60) not null,
  updated timestamp not null default CURRENT_TIMESTAMP,
  inserted timestamp not null default CURRENT_TIMESTAMP
);

CREATE TRIGGER phone_log_timestamp BEFORE INSERT OR UPDATE ON phone_log
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
