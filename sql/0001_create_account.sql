CREATE TABLE account(
  id serial not null PRIMARY KEY,
  email VARCHAR(128) NOT NULL UNIQUE,
  password VARCHAR(128) NOT NULL,
  name VARCHAR(128) NOT NULL UNIQUE,
  display_name varchar(128) not null,
  verified VARCHAR(128) NOT NULL DEFAULT 'NOTSENT',
  AccountSid VARCHAR(256) UNIQUE,
  stripe_code VARCHAR(256) UNIQUE,
  updated timestamp default CURRENT_TIMESTAMP,
  inserted timestamp default CURRENT_TIMESTAMP
);

CREATE TRIGGER user_timestamp BEFORE INSERT OR UPDATE ON account
FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
