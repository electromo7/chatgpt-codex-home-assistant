# Home Assistant Add-on: Codex Command Center

[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-Add--on-41BDF5?logo=homeassistant&logoColor=white)](https://www.home-assistant.io/)
[![Version](https://img.shields.io/badge/version-1.3.2-success)](./chatgpt-codex/config.yaml)
[![Stars welcome](https://img.shields.io/badge/⭐-Star%20this%20repo-yellow)](#support-the-project)

**Built specifically for Home Assistant**: Codex Command Center is a dedicated HA add-on that brings the OpenAI Codex CLI directly into your HA sidebar via secure Ingress access — with built-in Home Assistant API integration.

---

## Why this Home Assistant add-on stands out

- **Native Home Assistant UX** — launch directly in the HA sidebar with authentication.
- **Home Assistant API access** — query entities, call services, and control devices via natural language.
- **Entity overview** — auto-generated `HA_ENTITIES.md` gives Codex instant knowledge of all your devices.
- **Ready in minutes** — install add-on, paste API key, start building.
- **Production-minded defaults** — AppArmor profile, structured logs, configurable sessions.

## Feature highlights

- Ingress web terminal (ttyd) with HA authentication
- OpenAI Codex CLI pre-installed
- `ha-query` CLI for direct Home Assistant interaction (states, services, snapshots)
- Auto-generated entity snapshot (`HA_ENTITIES.md`) with editable room/notes column
- Multi-architecture support (amd64, aarch64)
- Theme + font-size customization
- Configurable max concurrent sessions
- Custom workspace and optional API base URL

## Quick install

1. Open **Home Assistant → Settings → Add-ons → Add-on Store**.
2. Click **⋮ → Repositories** and add this repository URL.
3. Install **Home Assistant Codex Command Center**.
4. Set your `openai_api_key`.
5. Start the add-on and open the Web UI.
6. Optional: Enable **Show in sidebar** for quick access.

## ha-query — Home Assistant CLI tool

The add-on includes `ha-query`, a CLI that lets Codex interact with Home Assistant:

```bash
# List all entities (or filter by domain/state)
ha-query states --domain light --state on --pretty

# Call a service (with dry-run safety)
ha-query call_service light.turn_off --entity_id light.wohnzimmer --dry-run

# Show HA system info
ha-query info --pretty

# Generate entity snapshot
ha-query snapshot
```

Just ask Codex in natural language — e.g. "Welche Lichter sind an?" or "Schalte das Gästezimmer-Licht aus" — and it uses `ha-query` automatically.

## Repository layout

```text
chatgpt-codex/
├── translations/
├── apparmor.txt
├── build.yaml
├── CHANGELOG.md
├── config.yaml
├── DOCS.md
├── Dockerfile
├── ha-query.sh
├── icon.png
├── logo.png
└── run.sh
```

## Support the project

If this add-on saves you time, please:

- ⭐ **Star this repository**
- 🍴 **Fork it for your own variant**
- 🐛 Open issues with reproducible bug reports
- 💡 Share ideas for integrations and workflows

This helps the project grow and makes it easier for others to discover.
