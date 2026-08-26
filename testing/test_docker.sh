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

    rlPhaseStartTest "Sanity test - initial configuration"
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

    rlPhaseStartTest "Sanity test - allows SSL connections"
        rlRun -t -s "docker exec -i web /Kiwi/manage.py showmigrations --database postgres_17"
        rlRun -t -s "docker exec -i web /Kiwi/manage.py showmigrations --database postgres_18"
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

    rlPhaseStartCleanup
        rlRun -t -c "docker compose down"
        if [ -n "$ImageOS" ]; then
            rlRun -t -c "docker volume rm postgres_db17_data"
            rlRun -t -c "docker volume rm postgres_db18_data"
        fi
    rlPhaseEnd
rlJournalEnd

rlJournalPrintText
