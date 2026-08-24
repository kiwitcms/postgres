FROM postgres:18@sha256:4aabea78cf39b90e834caf3af7d602a18565f6fe2508705c8d01aa63245c2e20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && curl -sSL https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | gpg --dearmor --output /usr/share/keyrings/datadog-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.datadoghq.com/ stable 7" > /etc/apt/sources.list.d/datadog.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends datadog-agent datadog-signing-keys \
    && rm -rf /var/lib/apt/lists/*
