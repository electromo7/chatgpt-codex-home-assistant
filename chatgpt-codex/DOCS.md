# Home Assistant Add-on: Codex Command Center

## Overview

This add-on provides a browser-based terminal running the OpenAI Codex CLI directly within Home Assistant. Access it through the Ingress panel in the sidebar — no extra ports or authentication needed. The add-on includes `ha-query`, a CLI tool that gives Codex direct access to your Home Assistant entities and services.

## Installation

1. Add this repository URL to your Home Assistant add-on store:
   **Settings > Add-ons > Add-on Store > Menu (⋮) > Repositories**
2. Find "Home Assistant Codex Command Center" in the store and click **Install**.
3. Configure your OpenAI API key in the add-on options.
4. Start the add-on and click **Open Web UI**.
5. Optional: Enable **Show in sidebar** for quick access from the HA sidebar.

## Configuration

### Required

| Option | Description |
|--------|-------------|
| `openai_api_key` | Your OpenAI API key. The add-on will not start without it. |

### Optional

| Option | Default | Description |
|--------|---------|-------------|
| `openai_base_url` | *(empty)* | Custom API endpoint (for proxies or compatible APIs). |
| `codex_args` | *(empty)* | Extra arguments passed to the `codex` command. |
| `workspace` | `/homeassistant` | Directory where Codex operates. Must be a mounted volume. |
| `theme` | `default` | Terminal theme: `default` or `dark`. |
| `font_size` | `14` | Terminal font size (8–32). |
| `max_sessions` | `1` | Maximum concurrent terminal sessions (1–5). |

## Access

### Via Ingress (recommended)

Click **Open Web UI** on the add-on page or use the sidebar entry. This is authenticated through Home Assistant — no separate login needed.

### Via direct port (optional)

If you set a host port for 7681/tcp in the add-on network configuration, you can access the terminal at `http://<your-ha-ip>:7681`. Note: this bypasses HA authentication.

## ha-query — Home Assistant CLI Tool

The add-on includes `ha-query` for direct Home Assistant API interaction. Codex uses it automatically when you ask questions about your smart home.

### Commands

```bash
# List entity states (all or filtered)
ha-query states
ha-query states --domain light --state on --pretty

# Call a Home Assistant service
ha-query call_service light.turn_off --entity_id light.wohnzimmer
ha-query call_service switch.turn_on --entity_id switch.licht_gastezimmer --dry-run

# Show Home Assistant system info
ha-query info --pretty

# Generate entity snapshot (auto-generated at startup)
ha-query snapshot
ha-query snapshot /homeassistant/HA_ENTITIES.md

# Debug token and API connectivity
ha-query debug
```

### Entity Snapshot (HA_ENTITIES.md)

At startup, the add-on generates `HA_ENTITIES.md` in the workspace directory. This file contains all Home Assistant entities grouped by domain (lights, switches, sensors, automations, scripts, media players, etc.) with a table format:

| Entity ID | Name | Status | Raum / Notiz |
|-----------|------|--------|--------------|
| `light.wohnzimmer` | Wohnzimmer Licht | on | |

You can manually edit the "Raum / Notiz" column to add room assignments or notes. Codex reads this file to quickly find the correct entity IDs.

To refresh the snapshot: `ha-query snapshot`

### Natural Language Usage

Just ask Codex in the terminal — it uses `ha-query` automatically:
- "Welche Lichter sind an?"
- "Schalte das Gästezimmer-Licht aus"
- "Zeig mir alle Sensoren"
- "Wie ist die Temperatur im Wohnzimmer?"

## Available Volumes

The add-on has access to these Home Assistant directories:

| Path | Access | Description |
|------|--------|-------------|
| `/homeassistant` | Read/Write | Home Assistant configuration |
| `/share` | Read/Write | Shared data between add-ons |
| `/addon_configs` | Read/Write | Add-on configuration files |
| `/ssl` | Read only | SSL certificates |

## Troubleshooting

### "No OpenAI API key configured"
Set your API key in the add-on configuration and restart.

### Terminal loads but Codex commands fail
Check that your API key is valid and has sufficient credits. Review the add-on log for error details.

### ha-query returns 401 Unauthorized
Run `ha-query debug` to check token availability and API connectivity. The add-on requires `homeassistant_api` and `hassio_api` permissions (configured automatically in `config.yaml`).

### Cannot access workspace
Ensure the configured workspace path points to a mounted volume (`/homeassistant`, `/share`, or `/addon_configs`).

### "Do you trust the contents of this directory?"
This prompt should be auto-skipped. If it persists, check the add-on logs for errors writing `~/.codex/config.toml`.
