#!/bin/bash

. /usr/share/beakerlib/beakerlib.sh

assert_up_and_running() {
    sleep 10
    # print health status for db and web containers
    rlRun -t -c "docker inspect -f '{{.State.Health.Status}}' web"

    # HTTP redirects; HTTPS displays the login page
    rlRun -t -c "curl       -o- http://localhost/  | grep '301 Moved Permanently'"
    rlRun -t -c "curl -k -L -o- https://localhost/ | grep 'Welcome to Kiwi TCMS'"
}

rlJournalStart
    rlPhaseStartTest "Container up"
        rlRun -t -c "docker compose up -d"
        sleep 5
    rlPhaseEnd

    rlPhaseStartTest "Sanity test - DB allows SSL connections - Kiwi TCMS initial_setup"
        # need to monkey-patch createsuperuser.py b/c it rejects input when not using a TTY
        rlRun -t -c 'docker exec -i web sed -i "s/raise NotRunningInTTYException/pass/" /venv/lib64/python3.12/site-packages/django/contrib/auth/management/commands/createsuperuser.py'
        rlRun -t -c 'docker exec -i web sed -i "s/getpass.getpass/input/" /venv/lib64/python3.12/site-packages/django/contrib/auth/management/commands/createsuperuser.py'

        rlRun -t -c 'echo -e "super-root\nroot@example.com\nsecret-2a9a34cd-e51d-4039-b709-b45f629a5595\nsecret-2a9a34cd-e51d-4039-b709-b45f629a5595\n" | docker exec -i web /Kiwi/manage.py initial_setup --database postgres_17'
        rlRun -t -c 'echo -e "super-root\nroot@example.com\nsecret-2a9a34cd-e51d-4039-b709-b45f629a5595\nsecret-2a9a34cd-e51d-4039-b709-b45f629a5595\n" | docker exec -i web /Kiwi/manage.py initial_setup --database postgres_18'

        # assert only after initial configuration has been applied
        assert_up_and_running
    rlPhaseEnd

    rlPhaseStartTest "Sanity test - DB rejects plain/text connections"
        rlRun -t -s "docker exec -i web /Kiwi/manage.py showmigrations --database plain_text" 1

        rlAssertGrep "django.db.utils.OperationalError: connection failed:" "$rlRun_LOG"
        rlAssertGrep "pg_hba.conf rejects connection .* no encryption" "$rlRun_LOG"
    rlPhaseEnd

    rlPhaseStartTest "Start replication containers"
        rlRun -t -c "docker run -d --name=replica_17 --network=postgres_default -e POSTGRES_REPLICATION_USER=rpl_usr_17 -e POSTGRES_REPLICATION_PASSWORD=replicate-me -e POSTGRES_PRIMARY_HOST=postgres_17 postgres-postgres_17:latest"
        sleep 120
        rlRun -t -c "docker logs replica_17"

        rlRun -t -c "docker run -d --name=replica_18 --network=postgres_default -e POSTGRES_REPLICATION_USER=rpl_usr_18 -e POSTGRES_REPLICATION_PASSWORD=replicate-me -e POSTGRES_PRIMARY_HOST=postgres_18 postgres-postgres_18:latest"
        sleep 120
        rlRun -t -c "docker logs replica_18"
    rlPhaseEnd

    rlPhaseStartTest "Container restart"
        rlRun -t -c "docker compose restart"
        assert_up_and_running
    rlPhaseEnd

    rlPhaseStartTest "Container stop & start"
        rlRun -t -c "docker compose stop"
        sleep 5
        rlRun -t -c "docker compose start"
        assert_up_and_running
    rlPhaseEnd

    rlPhaseStartTest "Container kill & start"
        rlRun -t -c "docker compose kill"
        sleep 35
        rlRun -t -c "docker compose start"
        assert_up_and_running
    rlPhaseEnd

    rlPhaseStartTest "Check content in replicated databases"
        REPLICA_17_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' replica_17)
        rlRun -t -c "psql --dbname 'postgres://kiwitcms:kiwitcms@$REPLICA_17_ADDRESS/kiwitcms?sslmode=require' -c 'SELECT * FROM management_priority;' | grep '5 rows'"

        REPLICA_18_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' replica_18)
        rlRun -t -c "psql --dbname 'postgres://kiwitcms:kiwitcms@$REPLICA_18_ADDRESS/kiwitcms?sslmode=require' -c 'SELECT * FROM management_priority;' | grep '5 rows'"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun -t -c "docker kill replica_17"
        rlRun -t -c "docker rm replica_17"

        rlRun -t -c "docker kill replica_18"
        rlRun -t -c "docker rm replica_18"

        rlRun -t -c "docker compose down"
        if [ -n "$ImageOS" ]; then
            rlRun -t -c "docker volume rm postgres_db17_data"
            rlRun -t -c "docker volume rm postgres_db18_data"
        fi
    rlPhaseEnd
rlJournalEnd

rlJournalPrintText
