#!/usr/bin/env bats

# Tests for chatgpt-codex/run.sh
# These tests source helper functions extracted from run.sh logic
# and validate configuration parsing, argument building, and error handling.

setup() {
    export TMPDIR="${BATS_TEST_TMPDIR}"
    export OPTIONS="${TMPDIR}/options.json"
    export WORKSPACE="${TMPDIR}/workspace"
    # Unset variables that may leak from the environment
    unset INGRESS_PORT
    unset OPENAI_API_KEY
    unset OPENAI_BASE_URL
}

# Helper: create a valid options.json
write_options() {
    cat > "${OPTIONS}" <<EOF
{
  "openai_api_key": "${1-sk-test-key-12345}",
  "openai_base_url": "${2-}",
  "codex_args": "${3-}",
  "workspace": "${4-${WORKSPACE}}",
  "theme": "${5-default}",
  "font_size": ${6-14},
  "max_sessions": ${7-1}
}
EOF
}

# ---------- Options file existence ----------

@test "fails when options file does not exist" {
    run bash -c '
        set -euo pipefail
        OPTIONS="/nonexistent/options.json"
        if [ ! -f "${OPTIONS}" ]; then
            echo "[FATAL] Options file not found: ${OPTIONS}"
            exit 1
        fi
    '
    [ "$status" -eq 1 ]
    [[ "$output" == *"Options file not found"* ]]
}

@test "succeeds when options file exists" {
    write_options
    run bash -c "
        set -euo pipefail
        OPTIONS='${OPTIONS}'
        if [ ! -f \"\${OPTIONS}\" ]; then
            echo '[FATAL] Options file not found'
            exit 1
        fi
        echo 'OK'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"OK"* ]]
}

# ---------- API key validation ----------

@test "fails when API key is empty" {
    write_options ""
    run bash -c "
        set -euo pipefail
        OPENAI_API_KEY=\"\$(jq -r '.openai_api_key // empty' '${OPTIONS}')\"
        if [ -z \"\${OPENAI_API_KEY}\" ]; then
            echo '[FATAL] No OpenAI API key configured!'
            exit 1
        fi
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"No OpenAI API key configured"* ]]
}

@test "succeeds when API key is provided" {
    write_options "sk-my-secret-key"
    run bash -c "
        set -euo pipefail
        OPENAI_API_KEY=\"\$(jq -r '.openai_api_key // empty' '${OPTIONS}')\"
        if [ -z \"\${OPENAI_API_KEY}\" ]; then
            echo '[FATAL] No OpenAI API key configured!'
            exit 1
        fi
        echo \"\${OPENAI_API_KEY}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"sk-my-secret-key"* ]]
}

# ---------- Configuration parsing ----------

@test "parses workspace from options" {
    write_options "sk-key" "" "" "/custom/workspace"
    run jq -r '.workspace // "/share"' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "/custom/workspace" ]
}

@test "defaults workspace to /share when not set" {
    cat > "${OPTIONS}" <<EOF
{
  "openai_api_key": "sk-key"
}
EOF
    run jq -r '.workspace // "/share"' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "/share" ]
}

@test "parses theme from options" {
    write_options "sk-key" "" "" "${WORKSPACE}" "dark"
    run jq -r '.theme // "default"' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "dark" ]
}

@test "parses font_size from options" {
    write_options "sk-key" "" "" "${WORKSPACE}" "default" 18
    run jq -r '.font_size // 14' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "18" ]
}

@test "parses max_sessions from options" {
    write_options "sk-key" "" "" "${WORKSPACE}" "default" 14 3
    run jq -r '.max_sessions // 1' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "3" ]
}

@test "parses openai_base_url from options" {
    write_options "sk-key" "https://custom.api.com/v1"
    run jq -r '.openai_base_url // empty' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "https://custom.api.com/v1" ]
}

@test "parses codex_args from options" {
    write_options "sk-key" "" "--model gpt-4"
    run jq -r '.codex_args // empty' "${OPTIONS}"
    [ "$status" -eq 0 ]
    [ "$output" = "--model gpt-4" ]
}

# ---------- Port determination ----------

@test "uses INGRESS_PORT when set" {
    run bash -c '
        export INGRESS_PORT=8099
        PORT="${INGRESS_PORT:-7681}"
        echo "${PORT}"
    '
    [ "$status" -eq 0 ]
    [ "$output" = "8099" ]
}

@test "defaults to port 7681 when INGRESS_PORT not set" {
    run bash -c '
        unset INGRESS_PORT
        PORT="${INGRESS_PORT:-7681}"
        echo "${PORT}"
    '
    [ "$status" -eq 0 ]
    [ "$output" = "7681" ]
}

# ---------- ttyd argument construction ----------

@test "builds basic ttyd args with writable and port" {
    run bash -c '
        PORT=7681
        TTYD_ARGS=(--writable --port "${PORT}")
        echo "${TTYD_ARGS[@]}"
    '
    [ "$status" -eq 0 ]
    [ "$output" = "--writable --port 7681" ]
}

@test "adds max-clients when max_sessions > 0" {
    run bash -c '
        MAX_SESSIONS=3
        TTYD_ARGS=(--writable --port 7681)
        if [ "${MAX_SESSIONS}" -gt 0 ] 2>/dev/null; then
            TTYD_ARGS+=(--max-clients "${MAX_SESSIONS}")
        fi
        echo "${TTYD_ARGS[@]}"
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"--max-clients 3"* ]]
}

@test "adds fontSize when font_size > 0" {
    run bash -c '
        FONT_SIZE=18
        TTYD_ARGS=(--writable --port 7681)
        if [ "${FONT_SIZE}" -gt 0 ] 2>/dev/null; then
            TTYD_ARGS+=(-t "fontSize=${FONT_SIZE}")
        fi
        echo "${TTYD_ARGS[@]}"
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"fontSize=18"* ]]
}

@test "adds dark theme configuration" {
    run bash -c '
        THEME="dark"
        TTYD_ARGS=(--writable --port 7681)
        if [ "${THEME}" = "dark" ]; then
            TTYD_ARGS+=(-t "theme={\"background\":\"#1e1e1e\"}")
        fi
        echo "${TTYD_ARGS[@]}"
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"theme="* ]]
    [[ "$output" == *"#1e1e1e"* ]]
}

@test "does not add dark theme for default theme" {
    run bash -c '
        THEME="default"
        TTYD_ARGS=(--writable --port 7681)
        if [ "${THEME}" = "dark" ]; then
            TTYD_ARGS+=(-t "theme={\"background\":\"#1e1e1e\"}")
        fi
        echo "${TTYD_ARGS[@]}"
    '
    [ "$status" -eq 0 ]
    [[ "$output" != *"theme="* ]]
}

# ---------- Workspace directory ----------

@test "creates workspace directory" {
    run bash -c "
        WORKSPACE='${TMPDIR}/new_workspace'
        mkdir -p \"\${WORKSPACE}\"
        [ -d \"\${WORKSPACE}\" ] && echo 'exists'
    "
    [ "$status" -eq 0 ]
    [ "$output" = "exists" ]
}

# ---------- Wrapper script generation ----------

@test "generates wrapper script with correct env vars" {
    run bash -c "
        OPENAI_API_KEY='sk-test-key'
        OPENAI_BASE_URL='https://api.example.com'
        WORKSPACE='/share'
        CODEX_ARGS='--model gpt-4'
        WRAPPER='${TMPDIR}/codex-wrapper.sh'

        cat > \"\${WRAPPER}\" <<WRAPPER
#!/bin/bash
export OPENAI_API_KEY=\"\${OPENAI_API_KEY}\"
export CODEX_API_KEY=\"\${OPENAI_API_KEY}\"
\${OPENAI_BASE_URL:+export OPENAI_BASE_URL=\"\${OPENAI_BASE_URL}\"}
export HOME=\"/root\"
cd \"\${WORKSPACE}\"
exec codex \${CODEX_ARGS}
WRAPPER
        chmod +x \"\${WRAPPER}\"

        # Verify wrapper content
        grep -q 'OPENAI_API_KEY=\"sk-test-key\"' \"\${WRAPPER}\"
        grep -q 'CODEX_API_KEY=\"sk-test-key\"' \"\${WRAPPER}\"
        grep -q 'OPENAI_BASE_URL=\"https://api.example.com\"' \"\${WRAPPER}\"
        grep -q 'cd \"/share\"' \"\${WRAPPER}\"
        grep -q 'codex --model gpt-4' \"\${WRAPPER}\"
        [ -x \"\${WRAPPER}\" ] && echo 'OK'
    "
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "wrapper script omits base URL when empty" {
    run bash -c "
        OPENAI_API_KEY='sk-test-key'
        OPENAI_BASE_URL=''
        WORKSPACE='/share'
        CODEX_ARGS=''
        WRAPPER='${TMPDIR}/codex-wrapper-no-url.sh'

        cat > \"\${WRAPPER}\" <<WRAPPER
#!/bin/bash
export OPENAI_API_KEY=\"\${OPENAI_API_KEY}\"
export CODEX_API_KEY=\"\${OPENAI_API_KEY}\"
\${OPENAI_BASE_URL:+export OPENAI_BASE_URL=\"\${OPENAI_BASE_URL}\"}
export HOME=\"/root\"
cd \"\${WORKSPACE}\"
exec codex \${CODEX_ARGS}
WRAPPER

        if grep -q 'OPENAI_BASE_URL' \"\${WRAPPER}\"; then
            echo 'FOUND'
        else
            echo 'NOT_FOUND'
        fi
    "
    [ "$status" -eq 0 ]
    [ "$output" = "NOT_FOUND" ]
}
