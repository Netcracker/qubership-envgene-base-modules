### Stage 1 - Build
FROM python:3.12-alpine3.23 AS build

RUN apk add --no-cache \
    gcc=15.2.0-r2 \
    musl-dev=1.2.5-r22 \
    libffi-dev=3.5.2-r0 \
    openssl-dev=3.5.6-r0 \
    libxml2-dev=2.13.9-r0 \
    libxslt-dev=1.1.43-r3 \
    zlib-dev=1.3.2-r0 \
    git=2.52.0-r0 \
    curl=8.17.0-r1 \
    jq=1.8.1-r0 \
    openssh=10.2_p1-r0 \
    zip=3.0-r13 \
    unzip=6.0-r16

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt
COPY build/requirements.txt /build/requirements.txt

RUN python -m venv /module/venv \
    && /module/venv/bin/pip install --no-cache-dir pip==26.0.1 setuptools==81.0.0 wheel==0.46.3 \
    && /module/venv/bin/pip install --no-cache-dir --retries 10 --timeout 60 -r /build/requirements.txt

RUN curl -sSL -o /usr/local/bin/sops \
    https://github.com/mozilla/sops/releases/download/v3.12.2/sops-v3.12.2.linux.amd64 \
    && chmod +x /usr/local/bin/sops


### Stage 2 - Runtime
FROM python:3.12-alpine3.23 AS runtime

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt

RUN apk add --no-cache \
    gcc=15.2.0-r2 \
    musl-dev=1.2.5-r22 \
    bash=5.3.3-r1 \
    ca-certificates=20251003-r0 \
    tar=1.35-r4 \
    curl=8.17.0-r1 \
    jq=1.8.1-r0 \
    yq-go=4.49.2-r4 \
    gettext=0.24.1-r1 \
    sed=4.9-r2 \
    age=1.2.1-r13 \
    git=2.52.0-r0 \
    libffi=3.5.2-r0 \
    openssl=3.5.6-r0 \
    openssh=10.2_p1-r0 \
    zip=3.0-r13 \
    unzip=6.0-r16 \
    sudo=1.9.17_p2-r0

COPY --from=build /module /module
COPY --from=build /usr/local/bin/sops /usr/local/bin/sops
COPY scripts /module/scripts

RUN mkdir -p /__w/_temp/_runner_file_commands /github/workspace /github/home /builds /cache && \
    chmod 777 /__w/_temp/_runner_file_commands /github/workspace /github/home /builds /cache

RUN addgroup ci && adduser -D -h /module/ -s /bin/bash -G ci ci && \
    chown ci:ci -R /module && \
    chmod 754 /module/scripts/* && \
    chmod +x /usr/local/bin/sops

ENV PATH="/usr/sbin:/usr/bin:/sbin:/bin:/module/venv/bin" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /module/scripts
