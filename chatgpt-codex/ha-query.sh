#!/usr/bin/env bash
# ha-query — CLI tool for querying Home Assistant from within the add-on container.
# Uses the Supervisor API via $SUPERVISOR_TOKEN.

set -euo pipefail

###############################################################################
# Constants
###############################################################################
readonly API_BASE="http://supervisor/core/api"
readonly VERSION="1.0.0"

###############################################################################
# Helpers
###############################################################################

_usage() {
  cat <<'EOF'
Usage: ha-query <command> [options]

Commands:
  states          List entity states
  call_service    Call a Home Assistant service
  info            Show Home Assistant configuration info
  snapshot        Generate HA_ENTITIES.md overview of all entities

Global options:
  --help, -h      Show this help message
  --version       Show version

Run 'ha-query <command> --help' for command-specific options.
EOF
}

_usage_states() {
  cat <<'EOF'
Usage: ha-query states [options]

List entity states from Home Assistant.

Options:
  --domain DOMAIN   Filter by domain (e.g. light, switch, sensor)
  --state STATE     Filter by state value (e.g. on, off, unavailable)
  --pretty          Tabular output instead of raw JSON
  -h, --help        Show this help message
EOF
}

_usage_call_service() {
  cat <<'EOF'
Usage: ha-query call_service DOMAIN.SERVICE [options]

Call a Home Assistant service.

Arguments:
  DOMAIN.SERVICE           Service to call (e.g. light.turn_on)

Options:
  --entity_id ID           Target entity (e.g. light.living_room)
  --data '{"key":"val"}'   Additional service data as JSON object
  --dry-run                Show the request that would be sent without executing
  --pretty                 Pretty-print JSON output
  -h, --help               Show this help message
EOF
}

_usage_info() {
  cat <<'EOF'
Usage: ha-query info [options]

Show Home Assistant configuration info.

Options:
  --pretty    Tabular output instead of raw JSON
  -h, --help  Show this help message
EOF
}

_check_token() {
  # Try environment variables first (SUPERVISOR_TOKEN, HASSIO_TOKEN)
  if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
    SUPERVISOR_TOKEN="${HASSIO_TOKEN:-}"
  fi

  # Fall back to token files (Codex sandbox may strip env vars)
  if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
    local token_file=""
    for f in /tmp/ha-supervisor-token /run/ha-query-token; do
      if [[ -r "$f" ]]; then
        token_file="$f"
        break
      fi
    done

    if [[ -n "$token_file" ]]; then
      SUPERVISOR_TOKEN="$(cat "$token_file")"
    fi
  fi

  if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
    echo "Error: No Supervisor token found." >&2
    echo "Checked: \$SUPERVISOR_TOKEN, \$HASSIO_TOKEN, /tmp/ha-supervisor-token, /run/ha-query-token" >&2
    exit 1
  fi

  export SUPERVISOR_TOKEN
}

# Perform an API request.
# Usage: _api_request METHOD ENDPOINT [BODY]
# Writes response body to stdout. Returns non-zero on HTTP errors.
_api_request() {
  local method="$1"
  local endpoint="$2"
  local body="${3:-}"
  local url="${API_BASE}${endpoint}"

  local tmpfile
  tmpfile="$(mktemp)"
  trap 'rm -f "$tmpfile"' RETURN

  local curl_args=(
    --silent
    --show-error
    --fail-with-body
    -X "$method"
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}"
    -H "Content-Type: application/json"
    -w "\n%{http_code}"
    -o "$tmpfile"
  )

  if [[ -n "$body" ]]; then
    curl_args+=(--data "$body")
  fi

  local http_code
  http_code="$(curl "${curl_args[@]}" "$url" 2>/dev/null)" || true

  local response
  response="$(cat "$tmpfile")"

  if [[ "$http_code" -ge 400 ]] 2>/dev/null; then
    echo "Error: HTTP ${http_code} from ${endpoint}" >&2
    if [[ -n "$response" ]]; then
      echo "$response" >&2
    fi
    return 1
  fi

  # If http_code is empty (curl failed completely)
  if [[ -z "$http_code" ]]; then
    echo "Error: Failed to connect to Home Assistant API at ${url}" >&2
    if [[ -n "$response" ]]; then
      echo "$response" >&2
    fi
    return 1
  fi

  echo "$response"
}

###############################################################################
# Commands
###############################################################################

cmd_states() {
  local domain=""
  local state_filter=""
  local pretty=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --domain)
        domain="$2"
        shift 2
        ;;
      --state)
        state_filter="$2"
        shift 2
        ;;
      --pretty)
        pretty=true
        shift
        ;;
      -h|--help)
        _usage_states
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        _usage_states >&2
        exit 1
        ;;
    esac
  done

  _check_token

  local response
  response="$(_api_request GET /states)" || exit 1

  # Apply filters using jq --arg to prevent injection
  local jq_filter="."
  if [[ -n "$domain" ]]; then
    jq_filter="[.[] | select(.entity_id | startswith(\$domain + \".\"))]"
  fi
  if [[ -n "$state_filter" ]]; then
    if [[ "$jq_filter" == "." ]]; then
      jq_filter="[.[] | select(.state == \$state)]"
    else
      jq_filter="${jq_filter} | [.[] | select(.state == \$state)]"
    fi
  fi

  local result
  result="$(echo "$response" | jq --arg domain "$domain" --arg state "$state_filter" "$jq_filter")"

  if [[ "$pretty" == true ]]; then
    echo "$result" | jq -r '
      ["ENTITY_ID", "STATE", "LAST_CHANGED"],
      ["----------", "-----", "------------"],
      (.[] | [.entity_id, .state, .last_changed])
      | @tsv
    ' | column -t -s $'\t'
  else
    echo "$result"
  fi
}

cmd_call_service() {
  local service_target=""
  local entity_id=""
  local extra_data=""
  local dry_run=false
  local pretty=false

  # First positional arg is DOMAIN.SERVICE
  if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
    service_target="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --entity_id)
        entity_id="$2"
        shift 2
        ;;
      --data)
        extra_data="$2"
        shift 2
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --pretty)
        pretty=true
        shift
        ;;
      -h|--help)
        _usage_call_service
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        _usage_call_service >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$service_target" ]]; then
    echo "Error: DOMAIN.SERVICE argument is required." >&2
    _usage_call_service >&2
    exit 1
  fi

  # Validate format
  if [[ ! "$service_target" =~ ^[a-z_]+\.[a-z_]+$ ]]; then
    echo "Error: Service must be in DOMAIN.SERVICE format (e.g. light.turn_on)." >&2
    exit 1
  fi

  local domain="${service_target%%.*}"
  local service="${service_target#*.}"

  _check_token

  # Build request body safely with jq
  local body
  if [[ -n "$entity_id" && -n "$extra_data" ]]; then
    body="$(jq -n --arg eid "$entity_id" --argjson data "$extra_data" '$data + {entity_id: $eid}')"
  elif [[ -n "$entity_id" ]]; then
    body="$(jq -n --arg eid "$entity_id" '{entity_id: $eid}')"
  elif [[ -n "$extra_data" ]]; then
    body="$extra_data"
  else
    body="{}"
  fi

  local endpoint="/services/${domain}/${service}"

  if [[ "$dry_run" == true ]]; then
    echo "Dry run — would send:"
    echo "  POST ${API_BASE}${endpoint}"
    echo "  Body: ${body}"
    exit 0
  fi

  local response
  response="$(_api_request POST "$endpoint" "$body")" || exit 1

  if [[ "$pretty" == true ]]; then
    echo "$response" | jq .
  else
    echo "$response"
  fi
}

cmd_info() {
  local pretty=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pretty)
        pretty=true
        shift
        ;;
      -h|--help)
        _usage_info
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        _usage_info >&2
        exit 1
        ;;
    esac
  done

  _check_token

  local response
  response="$(_api_request GET /config)" || exit 1

  if [[ "$pretty" == true ]]; then
    echo "$response" | jq -r '
      "Home Assistant Info",
      "===================",
      "Location:    \(.location_name)",
      "Version:     \(.version)",
      "Time Zone:   \(.time_zone)",
      "Elevation:   \(.elevation)m",
      "Unit System: \(.unit_system.temperature) / \(.unit_system.length)",
      "Components:  \(.components | length) loaded"
    '
  else
    echo "$response"
  fi
}

cmd_snapshot() {
  local output_file="${1:-HA_ENTITIES.md}"

  _check_token

  local response
  response="$(_api_request GET /states)" || exit 1

  # Also fetch config for system info
  local config
  config="$(_api_request GET /config)" || config="{}"

  local location
  location="$(echo "$config" | jq -r '.location_name // "Home Assistant"')"
  local version
  version="$(echo "$config" | jq -r '.version // "unknown"')"

  # Domain display names (German)
  local -A domain_labels=(
    [light]="Lichter"
    [switch]="Schalter"
    [sensor]="Sensoren"
    [binary_sensor]="Binäre Sensoren (Bewegungsmelder etc.)"
    [automation]="Automationen"
    [script]="Scripts"
    [scene]="Szenen"
    [climate]="Klimageräte / Heizungen"
    [cover]="Rollläden / Abdeckungen"
    [fan]="Ventilatoren"
    [media_player]="Mediaplayer (TV, Alexa, Lautsprecher)"
    [camera]="Kameras"
    [lock]="Schlösser"
    [vacuum]="Staubsauger"
    [input_boolean]="Eingabe-Schalter"
    [input_number]="Eingabe-Zahlen"
    [input_select]="Eingabe-Auswahl"
    [input_text]="Eingabe-Text"
    [input_datetime]="Eingabe-Datum/Zeit"
    [input_button]="Eingabe-Buttons"
    [timer]="Timer"
    [counter]="Zähler"
    [button]="Buttons"
    [select]="Auswahlfelder"
    [number]="Zahlenwerte"
    [text]="Textfelder"
    [device_tracker]="Geräte-Tracker"
    [person]="Personen"
    [zone]="Zonen"
    [sun]="Sonne"
    [weather]="Wetter"
    [update]="Updates"
    [remote]="Fernbedienungen"
    [alarm_control_panel]="Alarmanlagen"
    [water_heater]="Warmwasserbereiter"
    [humidifier]="Luftbefeuchter"
    [notify]="Benachrichtigungen"
    [tts]="Text-to-Speech"
    [stt]="Speech-to-Text"
    [calendar]="Kalender"
    [todo]="To-Do Listen"
    [image]="Bilder"
    [siren]="Sirenen"
    [event]="Ereignisse"
    [valve]="Ventile"
    [lawn_mower]="Rasenmäher"
    [wake_word]="Wake Words"
    [conversation]="Konversation"
  )

  # Extract all domains and sort them
  local domains
  domains="$(echo "$response" | jq -r '[.[].entity_id | split(".")[0]] | unique | .[]')"

  # Build the markdown file
  {
    echo "# Home Assistant Entities — ${location}"
    echo ""
    echo "> Auto-generiert am $(date '+%Y-%m-%d %H:%M') | HA Version: ${version}"
    echo "> Aktualisieren: \`ha-query snapshot\`"
    echo "> Diese Datei kann manuell bearbeitet werden (z.B. Raum/Notizen ergänzen)."
    echo "> Eigene Änderungen bleiben erhalten, solange die Datei nicht überschrieben wird."
    echo ""

    for domain in $domains; do
      local label="${domain_labels[$domain]:-${domain}}"
      local count
      count="$(echo "$response" | jq --arg d "$domain" '[.[] | select(.entity_id | startswith($d + "."))] | length')"

      # Skip empty domains
      if [[ "$count" -eq 0 ]]; then
        continue
      fi

      echo "## ${label} (${domain}) — ${count} Entities"
      echo ""
      echo "| Entity ID | Name | Status | Raum / Notiz |"
      echo "|-----------|------|--------|--------------|"

      echo "$response" | jq -r --arg d "$domain" '
        [.[] | select(.entity_id | startswith($d + "."))]
        | sort_by(.attributes.friendly_name // .entity_id)
        | .[]
        | "| `" + .entity_id + "` | " + (.attributes.friendly_name // "-") + " | " + .state + " | |"
      '

      echo ""
    done

    echo "---"
    echo ""
    echo "## Hinweise"
    echo ""
    echo "- **Raum / Notiz**: Hier kannst du manuell Räume oder Hinweise eintragen"
    echo "- **Status**: Zeigt den Status zum Zeitpunkt des Snapshots"
    echo "- Aktualisiere mit \`ha-query snapshot\` (überschreibt die Datei!)"
    echo "- Tipp: Kopiere die Datei als \`HA_ENTITIES_CUSTOM.md\` um eigene Notizen dauerhaft zu sichern"
  } > "$output_file"

  echo "Snapshot written to ${output_file} ($(wc -l < "$output_file") lines)"
}

###############################################################################
# Main dispatch
###############################################################################

if [[ $# -eq 0 ]]; then
  _usage
  exit 0
fi

case "$1" in
  states)
    shift
    cmd_states "$@"
    ;;
  call_service)
    shift
    cmd_call_service "$@"
    ;;
  info)
    shift
    cmd_info "$@"
    ;;
  snapshot)
    shift
    cmd_snapshot "$@"
    ;;
  debug)
    echo "=== Token Discovery ==="
    echo "SUPERVISOR_TOKEN env: $([[ -n "${SUPERVISOR_TOKEN:-}" ]] && echo "yes (${#SUPERVISOR_TOKEN} chars)" || echo "no")"
    echo "HASSIO_TOKEN env:     $([[ -n "${HASSIO_TOKEN:-}" ]] && echo "yes (${#HASSIO_TOKEN} chars)" || echo "no")"
    echo "/tmp/ha-supervisor-token: $([ -r /tmp/ha-supervisor-token ] && echo "exists" || echo "not found")"
    _check_token
    echo ""
    echo "=== Testing API Endpoints ==="
    for url in \
      "http://supervisor/core/api/config" \
      "http://supervisor/core/config" \
      "http://supervisor/api/config" \
      "http://homeassistant:8123/api/config"; do
      code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" "$url" 2>/dev/null || echo "ERR")
      echo "  ${code}  ${url}"
    done
    ;;
  --help|-h)
    _usage
    exit 0
    ;;
  --version)
    echo "ha-query ${VERSION}"
    exit 0
    ;;
  *)
    echo "Error: Unknown command '$1'" >&2
    _usage >&2
    exit 1
    ;;
esac
