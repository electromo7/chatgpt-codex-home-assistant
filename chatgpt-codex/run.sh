#!/usr/bin/with-contenv bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"

OPENAI_API_KEY="$(jq -r '.openai_api_key // empty' "$OPTIONS_FILE")"
OPENAI_BASE_URL="$(jq -r '.openai_base_url // empty' "$OPTIONS_FILE")"
CODEX_ARGS="$(jq -r '.codex_args // empty' "$OPTIONS_FILE")"
WORKSPACE="$(jq -r '.workspace // "/share"' "$OPTIONS_FILE")"

if [[ -n "$OPENAI_API_KEY" ]]; then
  export OPENAI_API_KEY
fi

if [[ -n "$OPENAI_BASE_URL" ]]; then
  export OPENAI_BASE_URL
fi

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

echo "Starting ChatGPT Codex terminal on port 7681..."
exec ttyd \
  --writable \
  --port 7681 \
  --interface 0.0.0.0 \
  bash -lc "codex ${CODEX_ARGS}"
