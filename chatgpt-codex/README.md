# Home Assistant Add-on: ChatGPT Codex

Run the OpenAI Codex CLI inside Home Assistant through a browser-based terminal.

## Features

- **Ingress integration** — access the terminal directly from the HA sidebar, authenticated through Home Assistant
- **Codex CLI pre-installed** — ready to use out of the box
- **Multi-architecture** — supports amd64 and aarch64
- **Configurable** — API key, custom base URL, workspace path, terminal theme, font size, and session limits
- **AppArmor secured** — runs with a restrictive security profile
- **bashio-powered** — structured logging visible in the HA log viewer

## Quick Start

1. Add this repository to your Home Assistant add-on store.
2. Install the "ChatGPT Codex" add-on.
3. Set your `openai_api_key` in the add-on configuration.
4. Start the add-on and click **Open Web UI**.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `openai_api_key` | *(required)* | Your OpenAI API key |
| `openai_base_url` | *(empty)* | Custom API endpoint |
| `codex_args` | *(empty)* | Extra Codex CLI arguments |
| `workspace` | `/share` | Working directory |
| `theme` | `default` | Terminal theme (`default` or `dark`) |
| `font_size` | `14` | Terminal font size (8–32) |
| `max_sessions` | `1` | Max concurrent sessions (1–5) |

## Documentation

See [DOCS.md](DOCS.md) for detailed usage instructions and troubleshooting.
