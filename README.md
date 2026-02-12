# 🚀 Home Assistant Add-on: Codex Command Center

[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-Add--on-41BDF5?logo=homeassistant&logoColor=white)](https://www.home-assistant.io/)
[![Version](https://img.shields.io/badge/version-1.0.0-success)](./chatgpt-codex/config.yaml)
[![Stars welcome](https://img.shields.io/badge/⭐-Star%20this%20repo-yellow)](#support-the-project)

**Built specifically for Home Assistant**: Codex Command Center is a dedicated HA add-on that brings the OpenAI Codex CLI directly into your HA sidebar via secure Ingress access.

---

## ✨ Why this Home Assistant add-on stands out

- **Native Home Assistant UX** — launch directly in the HA sidebar with authentication.
- **Ready in minutes** — install add-on, paste API key, start building.
- **Production-minded defaults** — AppArmor profile, structured logs, configurable sessions.
- **Built for makers** — works great for automations, scripts, YAML workflows, and diagnostics.

## 🧩 Feature highlights

- Ingress web terminal (ttyd)
- OpenAI Codex CLI pre-installed
- Multi-architecture support (amd64, aarch64)
- Theme + font-size customization
- Configurable max concurrent sessions
- Custom workspace and optional API base URL

## ⚡ Quick install

1. Open **Home Assistant → Settings → Add-ons → Add-on Store**.
2. Click **⋮ → Repositories** and add this repository URL.
3. Install **Home Assistant Codex Command Center**.
4. Set your `openai_api_key`.
5. Start the add-on and open the Web UI.

## 🗂️ Repository layout

```text
chatgpt-codex/
├── translations/
├── apparmor.txt
├── build.yaml
├── CHANGELOG.md
├── config.yaml
├── DOCS.md
├── Dockerfile
├── icon.png
├── logo.png
└── run.sh
```

## 🤝 Support the project

If this add-on saves you time, please:

- ⭐ **Star this repository**
- 🍴 **Fork it for your own variant**
- 🐛 Open issues with reproducible bug reports
- 💡 Share ideas for integrations and workflows

This helps the project grow and makes it easier for others to discover.
