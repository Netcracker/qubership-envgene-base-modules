### Stage 1 - Build
FROM alpine:3.23 AS build

RUN apk add --no-cache \
    'curl=8.23.0-r0'

RUN curl -sSL -o /usr/local/bin/sops \
    https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.amd64 \
    && chmod +x /usr/local/bin/sops

### Stage 2 - Runtime
FROM alpine:3.23 AS runtime

RUN apk add --no-cache \
    'python3=3.12.15-r0' \
    'python3-pyc=3.12.15-r0' \
    'bash=5.3.3-r1' \
    'ca-certificates=20261020-r0' \
    'tar=1.35-r4' \
    'git=2.52.0-r0' \
    'libffi=3.5.2-r0' \
    'openssl=3.5.9-r0' \
    'zip=3.0-r13'

RUN addgroup ci && adduser -D -h /module/ -s /bin/bash -G ci ci

COPY --from=build /usr/local/bin/sops /usr/local/bin/sops

RUN mkdir -p /__w/_temp/_runner_file_commands /github/workspace /github/home /builds /cache && \
    chmod 777 /__w/_temp/_runner_file_commands /github/workspace /github/home /builds /cache

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
