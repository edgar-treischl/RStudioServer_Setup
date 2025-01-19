library(DBI)

# Provide the path to the config file/credentials
myhost <- "10.155.36.195"
credential <- "admin_pw"
db_user <- "treischl"


# Connect to the database
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "default_db",
  host = myhost,
  port = 5432,
  user = db_user,
  password = credential
)

# Test the connection
dbListTables(con)

dbDisconnect(con)



dplyr::copy_to(con, mtcars, temporary = FALSE)

# Create the table in the public schema explicitly


?db_copy_to


penguins <- palmerpenguins::penguins

dplyr::copy_to(con, penguins, temporary = FALSE)



dbExecute(con, "DELETE FROM public.mtcars;")

dbExecute(con, "DROP TABLE IF EXISTS mtcars;")
dbExecute(con, "DROP TABLE IF EXISTS penguins;")



result <- dbGetQuery(con, "SELECT COUNT(*) FROM public.mtcars;")
print(result)

# exit
dbDisconnect(con)


query <- "SELECT * FROM mtcars"
data <- dbGetQuery(con, query)

# Print the result
print(head(data))


mtcars

query_metadata <- "SELECT * FROM mtcars WHERE table_name = 'mtcars_data'"
metadata <- dbGetQuery(con, query_metadata)
print(metadata)


# Disconnect from the PostgreSQL database
dbDisconnect(con)


dbGetQuery(con, "
  SELECT schemaname, tablename
  FROM pg_catalog.pg_tables
  WHERE tablename = 'mtcars' AND schemaname = 'public';
")
