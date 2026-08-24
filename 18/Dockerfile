FROM postgres:18@sha256:06cad38a5d9f5d24b4d83d86def30795d5e4b757fedbf5281172b576dedcd941

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && curl -sSL https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | gpg --dearmor --output /usr/share/keyrings/datadog-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.datadoghq.com/ stable 7" > /etc/apt/sources.list.d/datadog.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends datadog-agent datadog-signing-keys \
    && rm -rf /var/lib/apt/lists/*
