#!/bin/bash

# Copyright (c) 2026 Alexander Todorov <atodorov@otb.bg>
#
# Licensed under GNU Affero General Public License v3 or later (AGPLv3+)
# https://www.gnu.org/licenses/agpl-3.0.html

set -eu

# these must be the actual content of the files
[ -z "$POSTGRES_SSL_CERT" ] && exit 1
[ -z "$POSTGRES_SSL_KEY" ] && exit 1

# IMPORTANT: to refresh these certificates copy them
# directly under $PGDATA once the server has been initialized
# WARNING: chown postgres:postgres
# WARNING: chmod 0600
echo "    **** Configure SSL certificate and key"
echo "$POSTGRES_SSL_CERT" > "$PGDATA/server.crt"
chown postgres:postgres "$PGDATA/server.crt"
chmod 0600  "$PGDATA/server.crt"

echo "$POSTGRES_SSL_KEY" > "$PGDATA/server.key"
chown postgres:postgres "$PGDATA/server.key"
chmod 0600  "$PGDATA/server.key"

echo "    **** Turn SSL mode ON"
psql --set ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER SYSTEM SET ssl TO 'ON';
EOSQL

echo "    **** Require SSL connections from clients"
sed -i "s/host all all all scram-sha-256/hostssl all all all scram-sha-256/" "$PGDATA/pg_hba.conf"

echo "# Explicitly allow replication over SSL" >> "$PGDATA/pg_hba.conf"
echo "hostssl replication all all scram-sha-256" >> "$PGDATA/pg_hba.conf"

echo "# Explicitly reject non-SSL connections" >> "$PGDATA/pg_hba.conf"
echo "hostnossl all all all reject" >> "$PGDATA/pg_hba.conf"
echo "hostnossl replication all all reject" >> "$PGDATA/pg_hba.conf"

cat "$PGDATA/pg_hba.conf"
