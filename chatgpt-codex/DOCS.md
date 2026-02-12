# Home Assistant Add-on: ChatGPT Codex

## Overview

This add-on provides a browser-based terminal running the OpenAI Codex CLI directly within Home Assistant. Access it through the Ingress panel in the sidebar — no extra ports or authentication needed.

## Installation

1. Add this repository URL to your Home Assistant add-on store:
   **Settings > Add-ons > Add-on Store > Menu (⋮) > Repositories**
2. Find "ChatGPT Codex" in the store and click **Install**.
3. Configure your OpenAI API key in the add-on options.
4. Start the add-on and click **Open Web UI**.

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
| `workspace` | `/share` | Directory where Codex operates. Must be a mounted volume. |
| `theme` | `default` | Terminal theme: `default` or `dark`. |
| `font_size` | `14` | Terminal font size (8–32). |
| `max_sessions` | `1` | Maximum concurrent terminal sessions (1–5). |

## Access

### Via Ingress (recommended)

Click **Open Web UI** on the add-on page or use the sidebar entry. This is authenticated through Home Assistant — no separate login needed.

### Via direct port (optional)

If you set a host port for 7681/tcp in the add-on network configuration, you can access the terminal at `http://<your-ha-ip>:7681`. Note: this bypasses HA authentication.

## Available Volumes

The add-on has access to these Home Assistant directories:

| Path | Access | Description |
|------|--------|-------------|
| `/share` | Read/Write | Shared data between add-ons |
| `/config` | Read/Write | Home Assistant configuration |
| `/addon_configs` | Read/Write | Add-on configuration files |
| `/ssl` | Read only | SSL certificates |

## Troubleshooting

### "No OpenAI API key configured"
Set your API key in the add-on configuration and restart.

### Terminal loads but Codex commands fail
Check that your API key is valid and has sufficient credits. Review the add-on log for error details.

### Cannot access workspace
Ensure the configured workspace path points to a mounted volume (`/share`, `/config`, or `/addon_configs`).
