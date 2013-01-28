create user kevin with password 'the_trinity';

grant select on table account to kevin;
grant insert on table account to kevin;
grant update on table account to kevin;
grant delete on table account to kevin;

grant select on table phone_log to kevin;
grant insert on table phone_log to kevin;
grant update on table phone_log to kevin;
grant delete on table phone_log to kevin;

grant select on table phone_key to kevin;
grant insert on table phone_key to kevin;
grant update on table phone_key to kevin;
grant delete on table phone_key to kevin;

grant select on table phone_value to kevin;
grant insert on table phone_value to kevin;
grant update on table phone_value to kevin;
grant delete on table phone_value to kevin;

GRANT USAGE, SELECT ON SEQUENCE account_id_seq TO kevin;
GRANT USAGE, SELECT ON SEQUENCE phone_key_id_seq TO kevin;
GRANT USAGE, SELECT ON SEQUENCE phone_log_id_seq TO kevin;
GRANT USAGE, SELECT ON SEQUENCE phone_value_id_seq TO kevin;
