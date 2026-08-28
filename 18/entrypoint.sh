#!/usr/bin/env bash

# Copyright (c) 2026 Alexander Todorov <atodorov@otb.bg>
#
# Licensed under GNU Affero General Public License v3 or later (AGPLv3+)
# https://www.gnu.org/licenses/agpl-3.0.html

echo "INFO: check if replication is configured"
if [ ! -s "$PGDATA/PG_VERSION" ] && [ -n "$POSTGRES_REPLICATION_USER" ]; then
    mkdir -p "$PGDATA"
    chmod 00700 "$PGDATA" || :

    if [ -z "$POSTGRES_REPLICATION_PASSWORD" ]; then
        echo "ERROR: POSTGRES_REPLICATION_PASSWORD is undefined"
        exit 1
    fi

    if [ -z "$POSTGRES_PRIMARY_HOST" ]; then
        echo "ERROR: POSTGRES_PRIMARY_HOST is undefined"
        exit 2
    fi

    echo "INFO: starting initial wal sync"
    pg_basebackup \
        --dbname "postgres://$POSTGRES_REPLICATION_USER:$POSTGRES_REPLICATION_PASSWORD@$POSTGRES_PRIMARY_HOST/postgres?sslmode=require" \
        --pgdata "$PGDATA" \
        --progress --verbose --write-recovery-conf --wal-method stream \
        --create-slot --slot "$POSTGRES_REPLICATION_USER"

    echo "INFO: completed initial wal sync"
fi

echo "INFO: starting postgres"
docker-entrypoint.sh "$@"
