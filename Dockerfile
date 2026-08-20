### Stage 1 - Build
FROM python:3.12.10-alpine3.20 AS build

RUN apk add --no-cache \
    gcc=13.2.1_git20240309-r1 \
    musl-dev=1.2.5-r3 \
    libffi-dev=3.4.6-r0 \
    openssl-dev=3.3.7-r0 \
    libxml2-dev=2.12.10-r0 \
    libxslt-dev=1.1.39-r2 \
    zlib-dev=1.3.2-r0 \
    git=2.45.4-r0 \
    curl=8.14.1-r2 \
    jq=1.7.1-r0 \
    openssh-client=9.7_p1-r5 \
    zip=3.0-r12 \
    unzip=6.0-r14

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt
COPY build/requirements.txt /build/requirements.txt

RUN python -m venv /module/venv \
    && /module/venv/bin/pip install --no-cache-dir pip==26.0.1 setuptools==81.0.0 wheel==0.46.3 \
    && /module/venv/bin/pip install --no-cache-dir --retries 10 --timeout 60 -r /build/requirements.txt

RUN curl -sSL -o /usr/local/bin/sops \
    https://github.com/mozilla/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64 \
    && chmod +x /usr/local/bin/sops

### Stage 2 - Runtime
FROM python:3.12.10-alpine3.20 AS runtime

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt

RUN apk add --no-cache \
    gcc=13.2.1_git20240309-r1 \
    musl-dev=1.2.5-r3 \
    bash=5.2.26-r0 \
    ca-certificates=20260413-r0 \
    tar=1.35-r2 \
    curl=8.14.1-r2 \
    jq=1.7.1-r0 \
    yq-go=4.44.1-r2 \
    gettext=0.22.5-r0 \
    sed=4.9-r2 \
    age=1.2.1-r0 \
    git=2.45.4-r0 \
    libffi=3.4.6-r0 \
    openssl=3.3.7-r0 \
    openssh-client=9.7_p1-r5 \
    zip=3.0-r12 \
    unzip=6.0-r14 \
    sudo=1.9.15_p5-r0

COPY --from=build /module /module
COPY --from=build /usr/local/bin/sops /usr/local/bin/sops
COPY scripts /module/scripts

RUN mkdir -p /__w/_temp/_runner_file_commands /github/workspace /github/home /builds /cache && \
    chmod 777 /__w/_temp/_runner_file_commands /github/workspace /github/home /builds /cache

RUN addgroup ci && adduser -D -h /module/ -s /bin/bash -G ci ci && \
    chown ci:ci -R /module && \
    chmod 754 /module/scripts/* && \
    chmod +x /usr/local/bin/sops

ENV PATH=/module/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /module/scripts
