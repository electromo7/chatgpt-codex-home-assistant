# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-02-12

### Added
- Ingress integration for terminal access through HA UI with authentication
- AppArmor security profile
- Multi-architecture support (amd64, aarch64) via `build.yaml`
- bashio-based configuration reading with structured logging
- API key validation at startup with clear error messages
- Terminal theme option (default/dark)
- Configurable font size (8-32)
- Maximum concurrent sessions setting (1-5)
- Translations for English and German
- User documentation (DOCS.md)
- CI/CD pipelines (shellcheck, hadolint, yamllint, Docker smoke test)

### Changed
- Migrated `run.sh` from `jq` to `bashio` for config handling
- Removed deprecated architectures (armhf, armv7, i386)
- Port 7681 no longer exposed by default (Ingress is primary access)

### Removed
- Direct `jq` dependency (replaced by bashio)

## [1.0.0] - 2025-01-01

### Added
- Initial scaffold with ttyd-based browser terminal
- Codex CLI pre-installed via npm
- Basic configuration options (API key, base URL, workspace, arguments)
