#!/usr/bin/env bash
set -euo pipefail

# Read configuration from Home Assistant options
OPTIONS="/data/options.json"

OPENAI_API_KEY="$(jq -r '.openai_api_key' ${OPTIONS})"
OPENAI_BASE_URL="$(jq -r '.openai_base_url // empty' ${OPTIONS})"
CODEX_ARGS="$(jq -r '.codex_args // empty' ${OPTIONS})"
WORKSPACE="$(jq -r '.workspace // "/share"' ${OPTIONS})"
THEME="$(jq -r '.theme // "default"' ${OPTIONS})"
FONT_SIZE="$(jq -r '.font_size // 14' ${OPTIONS})"
MAX_SESSIONS="$(jq -r '.max_sessions // 1' ${OPTIONS})"

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

# Build ttyd arguments
TTYD_ARGS=(--writable --port 7681 --interface 0.0.0.0)

if [ "${MAX_SESSIONS}" -gt 0 ] 2>/dev/null; then
    TTYD_ARGS+=(--max-clients "${MAX_SESSIONS}")
fi

if [ "${FONT_SIZE}" -gt 0 ] 2>/dev/null; then
    TTYD_ARGS+=(-t "fontSize=${FONT_SIZE}")
fi

if [ "${THEME}" = "dark" ]; then
    TTYD_ARGS+=(-t 'theme={"background":"#1e1e1e","foreground":"#d4d4d4","cursor":"#d4d4d4"}')
fi

echo "[INFO] Starting ChatGPT Codex terminal on port 7681..."
echo "[INFO] Workspace: ${WORKSPACE}"

# shellcheck disable=SC2086
exec ttyd "${TTYD_ARGS[@]}" bash -lc "codex ${CODEX_ARGS}"
