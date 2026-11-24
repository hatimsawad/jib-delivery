revoke execute on all functions in schema private from public, anon;
alter default privileges for role postgres in schema private
  revoke execute on functions from public;
