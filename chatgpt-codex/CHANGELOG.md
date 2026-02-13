# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.3.2] - 2026-02-13

### Added
- `ha-query` CLI tool for direct Home Assistant API access
  - `states` — list entity states with `--domain`/`--state` filters and `--pretty` output
  - `call_service` — call HA services with `--entity_id`, `--data`, `--dry-run` safety
  - `info` — show HA configuration
  - `snapshot` — generate `HA_ENTITIES.md` overview of all entities grouped by domain
  - `debug` — diagnose token and API connectivity
- Auto-generated `HA_ENTITIES.md` at startup with all entities (editable room/notes column)
- Auto-generated `AGENTS.md` at startup with Codex instructions for `ha-query` usage
- `homeassistant_api`, `hassio_api`, `auth_api` permissions in `config.yaml`
- Workspace auto-trusted via `~/.codex/config.toml` (skips trust prompt)
- `SUPERVISOR_TOKEN` persisted to `/tmp/ha-supervisor-token` for Codex sandbox compatibility
- `util-linux` package for `column` command (pretty table output)

### Fixed
- ShellCheck SC1008 for `with-contenv` shebang
- Hadolint DL3006/DL3016/DL3059 warnings in Dockerfile

## [1.0.0] - 2026-02-12

### Changed
- Reset project versioning to `1.0.0` for the production launch baseline
- Renamed the add-on to **Home Assistant Codex Command Center** to make HA scope explicit
- Refreshed repository and add-on presentation text for a launch-ready GitHub profile

### Included
- Ingress terminal integration with Home Assistant authentication
- AppArmor profile and multi-architecture image support
- Configurable terminal theme, font size, session limits, and workspace
- bashio-based configuration loading and structured startup logs
