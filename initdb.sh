#! /bin/sh

## Install postgres and initdb ##

# brew install postgres
# initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgres
# psql -l


## RUN THIS AFTER bad-db.sql DOWNLOADED ##

dropdb udiddit
createdb udiddit
psql -d udiddit -f bad-db.sql
