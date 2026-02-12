# Home Assistant Add-on: Codex Command Center (Home Assistant)

Run the OpenAI Codex CLI inside Home Assistant through a secure browser terminal.

## Features

- **Ingress integration** — open directly from the Home Assistant sidebar with HA authentication
- **Codex CLI pre-installed** — launch immediately after installation
- **Multi-architecture** — supports `amd64` and `aarch64`
- **Operator-friendly controls** — theme, font size, and session limits
- **Secure by default** — restrictive AppArmor profile
- **Observable runtime** — bashio-based structured logs in Home Assistant

## Quick Start

1. Add this repository to your Home Assistant add-on store.
2. Install the **Home Assistant Codex Command Center** add-on.
3. Set your `openai_api_key` in the add-on configuration.
4. Start the add-on and click **Open Web UI**.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `openai_api_key` | *(required)* | Your OpenAI API key |
| `openai_base_url` | *(empty)* | Optional custom API endpoint |
| `codex_args` | *(empty)* | Extra Codex CLI arguments |
| `workspace` | `/share` | Working directory |
| `theme` | `default` | Terminal theme (`default` or `dark`) |
| `font_size` | `14` | Terminal font size (8–32) |
| `max_sessions` | `1` | Maximum concurrent sessions (1–5) |

## Documentation

See [DOCS.md](DOCS.md) for detailed usage and troubleshooting.
