#!/bin/bash
# Create user
sudo -u postgres psql -c "CREATE USER name WITH PASSWORD '1234';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE default_db TO name;"


# Create Superuser
# Set username variable
USER_NAME='name'


# Create new user as superuser with password
sudo -u postgres psql -c "CREATE USER ${USER_NAME} WITH SUPERUSER PASSWORD 'good_password';"


# Grant connection privileges to the user
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE default_db TO ${USER_NAME};"

# Connect to the database and set up schema permissions
sudo -u postgres psql default_db << EOQ
-- Grant usage and create on schema
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT CREATE ON SCHEMA public TO PUBLIC;

-- Grant all privileges on all current tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO PUBLIC;

-- Set default privileges for future objects created by postgres
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO PUBLIC;

-- Set default privileges for future objects created by the new user
-- Using the correct syntax to set the user_name
ALTER DEFAULT PRIVILEGES FOR USER ${USER_NAME} IN SCHEMA public GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES FOR USER ${USER_NAME} IN SCHEMA public GRANT ALL ON SEQUENCES TO PUBLIC;

-- Ensure search_path is set correctly
ALTER DATABASE default_db SET search_path TO public;

-- Make all existing tables readable for all users
DO
\$function\$
DECLARE
    _table text;
BEGIN
    FOR _table IN 
        SELECT quote_ident(tablename) FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'GRANT ALL ON TABLE ' || _table || ' TO PUBLIC';
    END LOOP;
END
\$function\$;

-- Revoke create schema permission from PUBLIC
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Grant create to specific users (including the one specified by USER_NAME)
GRANT CREATE ON SCHEMA public TO ${USER_NAME};

-- Set default permissions for new objects (global settings)
ALTER DEFAULT PRIVILEGES GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES GRANT ALL ON SEQUENCES TO PUBLIC;
ALTER DEFAULT PRIVILEGES GRANT ALL ON FUNCTIONS TO PUBLIC;
ALTER DEFAULT PRIVILEGES GRANT ALL ON TYPES TO PUBLIC;
EOQ

echo "Permissions set successfully."
