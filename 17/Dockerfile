FROM postgres:17@sha256:e38411452a464af89e5adadb8d223bf53b898d47d6ef918b2d58c08707350449

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && curl -sSL https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | gpg --dearmor --output /usr/share/keyrings/datadog-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.datadoghq.com/ stable 7" > /etc/apt/sources.list.d/datadog.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends datadog-agent \
    && apt-get clean

# Entrypoint: start agent, then your app
#CMD service datadog-agent start && exec ./start-my-app.sh
