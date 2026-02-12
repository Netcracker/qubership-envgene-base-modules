#######################################
# Stage 1 
FROM python:3.12-alpine3.19 AS build

COPY build/sources.list /etc/apk/repositories
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
    && /module/venv/bin/pip install --upgrade pip setuptools \
    && /module/venv/bin/pip install --no-cache-dir -r /build/requirements.txt
# Download and install SOPS for secrets management
RUN wget --tries=3 --progress=dot:giga \
    https://github.com/mozilla/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64 \
    -O /usr/local/bin/sops && \
    chmod +x /usr/local/bin/sops



#######################################
# Stage 2
FROM python:3.12-alpine3.19 AS runtime

COPY build/pip.conf /etc/pip.conf
COPY build/constraint.txt /build/constraint.txt

COPY build/sources.list /etc/apk/repositories
RUN apk add --no-cache \
    bash \
    ca-certificates \
    tar \
    curl \
    jq \
    yq \
    gettext \
    sed \
    age

COPY --from=build /module /module
COPY --from=build /usr/local/bin/sops /usr/local/bin/sops
COPY scripts /module/scripts

RUN addgroup ci && adduser -D -h /module/ -s /bin/bash -G ci ci && \
    chown ci:ci -R /module && \
    chmod 754 /module/scripts/* && \
    chmod +x /usr/local/bin/sops

ENV PATH=/module/venv/bin:$PATH

USER ci:ci
WORKDIR /module/scripts
#ENTRYPOINT ["/bin/bash", "-c"] # https://github.com/moby/moby/issues/3753
