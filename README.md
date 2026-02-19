# Qubership Envgene Base Modules

A base Docker image containing common components and dependencies for Qubership Envgene images. This image is designed to be used as a foundation for [build_envgene](https://github.com/Netcracker/qubership-envgene), [build_pipegene](https://github.com/Netcracker/qubership-envgene), and [build_effective_set_generator](https://github.com/Netcracker/qubership-envgene) images.

## Overview

This image provides a consistent, lightweight Alpine-based environment with:

- **Python 3.12** and common Python packages for YAML processing, validation, and GitHub API integration
- **Secrets management** tools (SOPS, age) for decrypting credentials in CI/CD pipelines
- **Utility scripts** for credential decryption, CI config parsing, and certificate management
- **CI-friendly layout** with pre-created directories for GitHub Actions and GitLab CI

## Contents

### Python packages

- `shyaml` — YAML parsing for shell scripts
- `yamale` — YAML schema validation
- `prettytable` — formatted table output
- `cryptography` — Fernet encryption/decryption
- `PyYAML` — YAML processing
- `PyGithub` — GitHub API client

### Tools

- **SOPS** (v3.9.0) — Mozilla's secrets management tool
- **age** — encryption tool used with SOPS

### Utility scripts

| Script | Description |
|--------|-------------|
| `decrypt.sh` | Decrypt credentials using Fernet or SOPS/AGE based on environment variables |
| `decrypt_fernet.py` | Python helper for Fernet credential decryption |
| `get_include_list.sh` | Parse CI config files and extract project include lists (uses shyaml) |
| `show_validate.py` | Display validation reports in a formatted table |
| `update_ca_certs.sh` | Update CA certificates for Debian, CentOS, or Alpine |
| `logging_functions.sh` | Shared logging utilities (log_info, log_warn, log_error) |

### System packages

- **Runtime:** Bash, ca-certificates, cURL, jq, yq, gettext, sed, age, Git, openssh-client, ZIP, unzip, libffi, OpenSSL
- **Build stage:** gcc, musl-dev, libffi-dev, openssl-dev, libxml2-dev, libxslt-dev, zlib-dev (for compiling Python extensions)

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
