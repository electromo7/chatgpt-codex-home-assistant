# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Home Assistant add-on that exposes the OpenAI Codex CLI through a browser-based terminal (ttyd) on port 7681. The root README is in German; the add-on README (`chatgpt-codex/README.md`) is in English.

## Architecture

The add-on is a Docker container built on Home Assistant's Alpine Linux base image. The flow is:

1. Home Assistant starts the container and writes user config to `/data/options.json`
2. `run.sh` reads options with `jq`, exports `OPENAI_API_KEY`/`OPENAI_BASE_URL` as env vars
3. `ttyd` launches on port 7681 running `codex ${CODEX_ARGS}` in the configured workspace directory

All add-on code lives under `chatgpt-codex/`:
- `config.yaml` — add-on manifest (name, version, ports, volume mounts, option schema)
- `Dockerfile` — Alpine-based image installing Node.js, npm, ttyd, and `@openai/codex`
- `run.sh` — entry point script

`repository.yaml` at the root defines the add-on repository metadata for Home Assistant's store.

## Build and Run

```bash
# Build the Docker image manually
cd chatgpt-codex && docker build -t chatgpt-codex:latest .

# Or install via Home Assistant: Settings → Add-ons → Add-on Store → add this repo URL
```

## Testing

```bash
# Run all tests (requires pytest, pyyaml, bats)
./tests/run_tests.sh

# Run only Python config/structure tests
python3 -m pytest tests/test_config.py -v

# Run only shell script (bats) tests
bats tests/test_run.bats
```

**Dependencies**: `pip install pytest pyyaml` and `npm install -g bats`

Tests are organized as:
- `tests/test_config.py` — validates config.yaml schema, repository.yaml, translations, Dockerfile, and AppArmor profile (pytest)
- `tests/test_run.bats` — validates run.sh configuration parsing, API key validation, port logic, ttyd argument construction, and wrapper script generation (bats)

CI runs linting (yamllint, shellcheck, hadolint) and tests automatically on push/PR to main.

## Key Configuration (config.yaml)

- **Port**: 7681/tcp
- **Volumes**: `addon_config` (rw), `homeassistant_config` (rw), `share` (rw), `ssl` (ro)
- **Options**: `openai_api_key` (password), `openai_base_url`, `codex_args`, `workspace` (default `/share`)
- **Architectures**: aarch64, amd64, armhf, armv7, i386
