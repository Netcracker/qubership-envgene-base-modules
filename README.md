# Qubership Envgene Base Modules

A base Docker image containing common components and dependencies for Qubership Envgene images. This image is designed to be used as a foundation for [build_envgene](https://github.com/Netcracker/qubership-envgene), [build_pipegene](https://github.com/Netcracker/qubership-envgene), and [build_effective_set_generator](https://github.com/Netcracker/qubership-envgene) images.

## Overview

This image provides a consistent, lightweight Alpine-based environment with:

- **Python 3.12** without extra packages; the consuming image creates its own virtual environment
- **Secrets management** tools (SOPS, age) for decrypting credentials in CI/CD pipelines
- **CI-friendly layout** with pre-created directories for GitHub Actions and GitLab CI

## Contents

### Tools

- **SOPS** (v3.13.3) — Mozilla's secrets management tool
- **age** — encryption tool used with SOPS

### System packages

- **Runtime:** Bash, ca-certificates, cURL, jq, yq, gettext, sed, age, Git, openssh-client, ZIP, unzip, libffi, OpenSSL

## Usage

### As a base image

```dockerfile
FROM ghcr.io/netcracker/qubership-envgene-base-modules:latest
```

### Image location

Images are published to GitHub Container Registry:

```text
ghcr.io/netcracker/qubership-envgene-base-modules
```

## Building

```bash
docker build -t qubership-envgene-base-modules .
```

## Custom repositories

For environments with private package mirrors, uncomment the `COPY build/sources.list` lines in the Dockerfile and configure `build/sources.list` with your Alpine repository URLs.

## License

See [LICENSE](LICENSE) for details.
