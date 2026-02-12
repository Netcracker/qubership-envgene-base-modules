#######################################
# Stage 1 
FROM python:3.12-alpine3.19 AS build

# Optional: use custom repos (e.g. internal mirror) - uncomment if needed
# COPY build/sources.list /etc/apk/repositories
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    libxml2-dev \
    libxslt-dev \
    zlib-dev \
    git \
    curl \
    jq \
    openssh-client \
    zip \
    unzip

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt
COPY build/requirements.txt /build/requirements.txt

RUN python -m venv /module/venv \
    && /module/venv/bin/pip install --upgrade pip "setuptools<82" wheel \
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
    bash \
    ca-certificates \
    tar \
    curl \
    jq \
    yq \
    gettext \
    sed \
    age \
    git \
    libffi \
    openssl \
    openssh-client \
    zip \
    unzip

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

USER ci:ci
WORKDIR /module/scripts
#ENTRYPOINT ["/bin/bash", "-c"] # https://github.com/moby/moby/issues/3753
