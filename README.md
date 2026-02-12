# ChatGPT Codex Home Assistant Add-on Repository

Dieses Repository stellt ein Home-Assistant-Add-on bereit, das OpenAI Codex über ein Web-Terminal (`ttyd`) verfügbar macht.

## Inhalt

- `repository.yaml`: Metadaten für das Add-on-Repository
- `chatgpt-codex/`: Das eigentliche Add-on

## Add-on installieren

1. In Home Assistant zu **Einstellungen → Add-ons → Add-on Store** gehen.
2. Über **⋮ → Repositories** dieses Repository hinzufügen.
3. Das Add-on **ChatGPT Codex** installieren.
4. In den Add-on-Optionen den `openai_api_key` setzen.
5. Add-on starten und das Web-UI auf Port `7681` öffnen.

## Hinweise

- Dieses Projekt bildet funktional das bekannte Claude-Code-Add-on-Muster nach, aber für OpenAI Codex.
- Falls du 1:1 Dateinamen/Labels des Referenzprojekts möchtest, teile bitte die genaue Struktur mit (Netzwerkzugriff auf das Referenzrepo ist in dieser Umgebung blockiert).
