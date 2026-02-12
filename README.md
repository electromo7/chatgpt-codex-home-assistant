# ChatGPT Codex Home Assistant Add-on Repository

This repository provides a Home Assistant add-on that exposes OpenAI Codex through a browser-based terminal (`ttyd`).

## Features

- **Ingress integration** — access the terminal directly from the HA UI, protected by HA authentication
- **Multi-architecture** — amd64 and aarch64
- **AppArmor profile** — restrictive security profile
- **Configurable** — API key, theme, font size, max sessions
- **bashio-powered** — structured logging in the HA log viewer

## Installation

1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**.
2. Open **⋮ > Repositories** and add this repository URL.
3. Install the **ChatGPT Codex** add-on.
4. Set your `openai_api_key` in the add-on configuration.
5. Start the add-on and click **Open Web UI**.

## Project Structure

```
chatgpt-codex/
├── translations/       # Translations (EN/DE)
├── apparmor.txt        # AppArmor security profile
├── build.yaml          # Multi-arch build configuration
├── CHANGELOG.md        # Version history
├── config.yaml         # Add-on manifest
├── DOCS.md             # User documentation
├── Dockerfile          # Container build
├── icon.png            # Add-on icon
├── logo.png            # Add-on logo
└── run.sh              # Entry point script (bashio)
```

## Development

```bash
# Build the Docker image locally
cd chatgpt-codex && docker build -t chatgpt-codex:latest .
```

See [CHANGELOG.md](chatgpt-codex/CHANGELOG.md) for the version history.
