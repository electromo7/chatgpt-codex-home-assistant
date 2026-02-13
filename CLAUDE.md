# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Home Assistant add-on that exposes the OpenAI Codex CLI through a browser-based terminal (ttyd) with integrated Home Assistant API access via `ha-query`. The root README is in German; the add-on README (`chatgpt-codex/README.md`) is in English.

## Architecture

The add-on is a Docker container built on Home Assistant's Alpine Linux base image. The flow is:

1. Home Assistant starts the container and writes user config to `/data/options.json`
2. `run.sh` reads options with `jq`, exports `OPENAI_API_KEY`/`OPENAI_BASE_URL`/`SUPERVISOR_TOKEN` as env vars
3. `run.sh` generates `~/.codex/config.toml` (workspace trust), `AGENTS.md` (Codex instructions), and `HA_ENTITIES.md` (entity snapshot)
4. `ttyd` launches via Ingress running `codex ${CODEX_ARGS}` in the configured workspace directory

All add-on code lives under `chatgpt-codex/`:
- `config.yaml` — add-on manifest (name, version, ports, API permissions, option schema)
- `Dockerfile` — Alpine-based image installing Node.js, npm, ttyd, util-linux, and `@openai/codex`
- `run.sh` — entry point script (config, auth, token persistence, Codex setup, ttyd launch)
- `ha-query.sh` — CLI tool for querying HA states, calling services, generating entity snapshots

### ha-query CLI

Installed at `/usr/local/bin/ha-query`, this script provides Codex with direct Home Assistant access:
- `ha-query states` — list entity states with optional `--domain`/`--state` filters
- `ha-query call_service DOMAIN.SERVICE` — call HA services with `--entity_id`, `--data`, `--dry-run`
- `ha-query info` — show HA configuration
- `ha-query snapshot [FILE]` — generate markdown overview of all entities grouped by domain
- `ha-query debug` — diagnose token and API connectivity

Uses `http://supervisor/core/api/` with `$SUPERVISOR_TOKEN` (persisted to `/tmp/ha-supervisor-token` for sandbox compatibility).

### Generated files (written to workspace at startup)

- `AGENTS.md` — instructions for Codex on how to use `ha-query`
- `HA_ENTITIES.md` — snapshot of all HA entities with names, states, and editable notes column

`repository.yaml` at the root defines the add-on repository metadata for Home Assistant's store.

## Build and Run

```bash
# Build the Docker image manually
cd chatgpt-codex && docker build -t chatgpt-codex:latest .

# Or install via Home Assistant: Settings → Add-ons → Add-on Store → add this repo URL
```

CI runs on every push via `.github/workflows/build.yaml`: yamllint, shellcheck, hadolint, and Docker build + smoke test.

## Key Configuration (config.yaml)

- **Ingress**: enabled (authenticated via HA)
- **API access**: `homeassistant_api`, `hassio_api`, `auth_api` (required for `ha-query`)
- **Volumes**: `addon_config` (rw), `homeassistant_config` (rw), `share` (rw), `ssl` (ro)
- **Options**: `openai_api_key` (password), `openai_base_url`, `codex_args`, `workspace` (default `/homeassistant`), `theme`, `font_size`, `max_sessions`
- **Architectures**: aarch64, amd64
