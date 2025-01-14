-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

#docs
#https://docs.digitalocean.com/products/databases/postgresql/how-to/modify-user-privileges/
#https://www.digitalocean.com/community/tutorials/how-to-manage-sql-database-cheat-sheet#sql-cheat-sheet






-- Step 1: Revoke all privileges from user `api` on `defaultdb`
REVOKE ALL ON DATABASE defaultdb FROM api;

-- Step 2: Grant read-only access (CONNECT and SELECT) to user `api` on the database
GRANT CONNECT ON DATABASE defaultdb TO api;
GRANT USAGE ON SCHEMA public TO api;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO api;

-- Step 3: Grant full CRUD privileges to user `edgar` on the database
GRANT CONNECT, CREATE, TEMPORARY ON DATABASE defaultdb TO edgar;
GRANT USAGE ON SCHEMA public TO edgar;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO edgar;

-- Step 4: Grant CREATE privilege on the `public` schema to `edgar` (needed for creating new tables)
GRANT CREATE ON SCHEMA public TO edgar;

-- Step 5: Ensure that tables created by `edgar` will grant SELECT access to `api`
-- This grants `api` SELECT privileges on any new tables created by `edgar`
ALTER DEFAULT PRIVILEGES FOR ROLE edgar IN SCHEMA public GRANT SELECT ON TABLES TO api;

-- Step 6 (Optional): Ensure that new sequences created by `edgar` automatically grant `api` usage and select access
ALTER DEFAULT PRIVILEGES FOR ROLE edgar IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO api;







\du

\q





