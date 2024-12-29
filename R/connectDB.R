library(DBI)

# Provide the path to the config file/credentials
myhost <- config::get("server")
credential <- keyring::key_get(service = "digialocean")
db_user <- config::get("dbuser")


# Connect to the database
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "defaultdb",
  host = myhost,
  port = 5432,
  user = db_user,
  password = credential
)

# Test the connection
print(con)

dbListTables(con)

dplyr::copy_to(con, mtcars)

# exit
dbDisconnect(con)
