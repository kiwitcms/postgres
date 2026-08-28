#!/bin/bash

# Copyright (c) 2026 Alexander Todorov <atodorov@otb.bg>
#
# Licensed under GNU Affero General Public License v3 or later (AGPLv3+)
# https://www.gnu.org/licenses/agpl-3.0.html

set -eu

replication_user() {
    local username=$1
    local password=$2

    psql --set ON_ERROR_STOP=1 \
        --set=username="$username" \
        --set=password="$password" \
        --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE USER :"username" WITH ENCRYPTED PASSWORD :'password' REPLICATION;
EOSQL
}

replication_user "rpl_usr_17" "replicate-me"
replication_user "rpl_usr_18" "replicate-me"
