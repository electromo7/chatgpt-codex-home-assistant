#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

echo "[INFO] Home Assistant Codex Command Center add-on starting..."

# Read configuration from Home Assistant options
OPTIONS="/data/options.json"

if [ ! -f "${OPTIONS}" ]; then
    echo "[FATAL] Options file not found: ${OPTIONS}"
    exit 1
fi

echo "[DEBUG] Reading options..."
OPENAI_API_KEY="$(jq -r '.openai_api_key // empty' "${OPTIONS}")"
OPENAI_BASE_URL="$(jq -r '.openai_base_url // empty' "${OPTIONS}")"
CODEX_ARGS="$(jq -r '.codex_args // empty' "${OPTIONS}")"
WORKSPACE="$(jq -r '.workspace // "/share"' "${OPTIONS}")"
THEME="$(jq -r '.theme // "default"' "${OPTIONS}")"
FONT_SIZE="$(jq -r '.font_size // 14' "${OPTIONS}")"
MAX_SESSIONS="$(jq -r '.max_sessions // 1' "${OPTIONS}")"

# Validate API key
if [ -z "${OPENAI_API_KEY}" ]; then
    echo "[FATAL] No OpenAI API key configured!"
    echo "[FATAL] Please set your API key in the add-on configuration."
    exit 1
fi
export OPENAI_API_KEY

if [ -n "${OPENAI_BASE_URL}" ]; then
    export OPENAI_BASE_URL
    echo "[INFO] Using custom OpenAI base URL: ${OPENAI_BASE_URL}"
fi

# Prepare workspace
mkdir -p "${WORKSPACE}"
cd "${WORKSPACE}" || { echo "[FATAL] Cannot access workspace: ${WORKSPACE}"; exit 1; }

# Determine port: use HA ingress port if available, otherwise 7681
PORT="${INGRESS_PORT:-7681}"
echo "[DEBUG] INGRESS_PORT=${INGRESS_PORT:-not set}, using PORT=${PORT}"

# Build ttyd arguments
TTYD_ARGS=(--writable --port "${PORT}")

if [ "${MAX_SESSIONS}" -gt 0 ] 2>/dev/null; then
    TTYD_ARGS+=(--max-clients "${MAX_SESSIONS}")
fi

if [ "${FONT_SIZE}" -gt 0 ] 2>/dev/null; then
    TTYD_ARGS+=(-t "fontSize=${FONT_SIZE}")
fi

if [ "${THEME}" = "dark" ]; then
    TTYD_ARGS+=(-t 'theme={"background":"#1e1e1e","foreground":"#d4d4d4","cursor":"#d4d4d4"}')
fi

# Verify codex is installed
CODEX_PATH="$(command -v codex 2>/dev/null || true)"
if [ -z "${CODEX_PATH}" ]; then
    echo "[FATAL] codex command not found in PATH"
    echo "[DEBUG] PATH=${PATH}"
    echo "[DEBUG] Checking npm global bin..."
    ls -la "$(npm root -g)/../bin/" 2>/dev/null || true
    exit 1
fi
echo "[INFO] codex found at: ${CODEX_PATH}"

echo "[INFO] Starting Home Assistant Codex Command Center terminal on port ${PORT}..."
echo "[INFO] Workspace: ${WORKSPACE}"
echo "[DEBUG] ttyd args: ${TTYD_ARGS[*]}"

# Pre-authenticate codex with API key (avoids OAuth browser redirect)
export HOME="/root"
mkdir -p "${HOME}/.codex"
echo "[INFO] Logging in to codex with API key..."
printf '%s' "${OPENAI_API_KEY}" | codex login --with-api-key 2>&1 || {
    echo "[WARN] codex login failed, will try running anyway"
}

# Persist Supervisor token to file so ha-query can read it even inside Codex sandbox
if [[ -n "${SUPERVISOR_TOKEN:-}" ]]; then
    echo "${SUPERVISOR_TOKEN}" > /tmp/ha-supervisor-token
    chmod 644 /tmp/ha-supervisor-token
    cp /tmp/ha-supervisor-token /run/ha-query-token 2>/dev/null || true
    echo "[INFO] Supervisor token written (length: ${#SUPERVISOR_TOKEN})"
else
    echo "[WARN] SUPERVISOR_TOKEN not set — ha-query will not work"
fi

# Generate initial entity snapshot for Codex context
echo "[INFO] Generating entity snapshot..."
ha-query snapshot "${WORKSPACE}/HA_ENTITIES.md" 2>/dev/null && \
    echo "[INFO] Entity snapshot written to ${WORKSPACE}/HA_ENTITIES.md" || \
    echo "[WARN] Could not generate entity snapshot (HA Core may still be starting)"

# Write Codex instructions so it knows about ha-query
cat > "${WORKSPACE}/AGENTS.md" <<'AGENTS'
# Home Assistant Codex Agent

You have access to the `ha-query` CLI tool for interacting with Home Assistant.
Use it directly — do NOT search the codebase for it.

## Available commands

```bash
# List entity states (optionally filter by domain/state)
ha-query states [--domain light|switch|sensor|...] [--state on|off|...] [--pretty]

# Call a Home Assistant service
ha-query call_service DOMAIN.SERVICE --entity_id ENTITY_ID [--data '{"key":"val"}'] [--dry-run] [--pretty]

# Show Home Assistant system info
ha-query info [--pretty]
```

## Entity Overview

The file `HA_ENTITIES.md` in this directory contains a snapshot of ALL Home Assistant
entities with their names, IDs, and current states. **Read this file first** before
querying states — it tells you the exact entity_id for any device.

To refresh it: `ha-query snapshot HA_ENTITIES.md`

## Guidelines

- **Always read HA_ENTITIES.md first** to find the correct entity_id
- When the user asks about entities, lights, sensors, switches etc. → use `ha-query states`
- When the user wants to control devices → use `ha-query call_service`
- Always use `--dry-run` first for destructive or unfamiliar service calls
- Respond in the same language the user uses
AGENTS

# Write a wrapper script so ttyd sessions inherit the environment
cat > /tmp/codex-wrapper.sh <<WRAPPER
#!/bin/bash
export OPENAI_API_KEY="${OPENAI_API_KEY}"
export CODEX_API_KEY="${OPENAI_API_KEY}"
${OPENAI_BASE_URL:+export OPENAI_BASE_URL="${OPENAI_BASE_URL}"}
export SUPERVISOR_TOKEN="${SUPERVISOR_TOKEN:-}"
export HASSIO_TOKEN="${SUPERVISOR_TOKEN:-}"
export HOME="/root"
cd "${WORKSPACE}"
exec codex ${CODEX_ARGS}
WRAPPER
chmod +x /tmp/codex-wrapper.sh

# shellcheck disable=SC2086
exec ttyd "${TTYD_ARGS[@]}" /tmp/codex-wrapper.sh
