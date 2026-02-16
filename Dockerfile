#######################################
# Stage 1 
FROM python:3.12-alpine3.19 AS build

# Optional: use custom repos (e.g. internal mirror) - uncomment if needed
# COPY build/sources.list /etc/apk/repositories
RUN apk add --no-cache \
    gcc=13.2.1_git20231014-r0 \
    musl-dev=1.2.4_git20230717-r5 \
    libffi-dev=3.4.4-r3 \
    openssl-dev=3.1.8-r1 \
    libxml2-dev=2.11.8-r3 \
    libxslt-dev=1.1.39-r1 \
    zlib-dev=1.3.1-r0 \
    git=2.43.7-r0 \
    curl=8.14.1-r2 \
    jq=1.7.1-r0 \
    openssh-client=9.6_p1-r2 \
    zip=3.0-r12 \
    unzip=6.0-r14

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt
COPY build/requirements.txt /build/requirements.txt

RUN python -m venv /module/venv \
    && /module/venv/bin/pip install --no-cache-dir pip==26.0.1 setuptools==81.0.0 wheel==0.46.3 \
    && /module/venv/bin/pip install --no-cache-dir --retries 10 --timeout 60 -r /build/requirements.txt
# Download and install SOPS for secrets management
RUN curl -sSL -o /usr/local/bin/sops \
    https://github.com/mozilla/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64 \
    && chmod +x /usr/local/bin/sops



#######################################
# Stage 2
FROM python:3.12-alpine3.19 AS runtime

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt

# Optional: use custom repos - uncomment if needed
# COPY build/sources.list /etc/apk/repositories
RUN apk add --no-cache \
    bash=5.2.21-r0 \
    ca-certificates=20240226-r0 \
    tar=1.35-r2 \
    curl=8.14.1-r2 \
    jq=1.7.1-r0 \
    yq=4.35.2-r4 \
    gettext=0.22.3-r0 \
    sed=4.9-r2 \
    age=1.1.1-r11 \
    git=2.43.7-r0 \
    libffi=3.4.4-r3 \
    openssl=3.1.8-r1 \
    openssh-client=9.6_p1-r2 \
    zip=3.0-r12 \
    unzip=6.0-r14 \
    sudo=1.9.14p3-r0

COPY --from=build /module /module
COPY --from=build /usr/local/bin/sops /usr/local/bin/sops
COPY scripts /module/scripts

# Create directories for CI environments (GitHub Actions, GitLab CI)
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
#ENTRYPOINT ["/bin/bash", "-c"] # https://github.com/moby/moby/issues/3753
