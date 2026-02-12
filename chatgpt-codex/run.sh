#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] ChatGPT Codex add-on starting..."

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

# Build ttyd arguments
TTYD_ARGS=(--writable --port "${PORT}" --base-path /)

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

echo "[INFO] Starting ChatGPT Codex terminal on port ${PORT}..."
echo "[INFO] Workspace: ${WORKSPACE}"
echo "[DEBUG] ttyd args: ${TTYD_ARGS[*]}"

# shellcheck disable=SC2086
exec ttyd "${TTYD_ARGS[@]}" bash -lc "codex ${CODEX_ARGS}"
