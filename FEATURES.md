# Feature-Ideen / Feature Brainstorm

Gesammelte Ideen fuer zukuenftige Erweiterungen des ChatGPT Codex Home Assistant Add-ons.

---

## 1. Mehrere LLM-Provider unterstuetzen

**Status:** Idee
**Aufwand:** Mittel

Aktuell ist das Add-on auf OpenAI fixiert. Viele Nutzer verwenden aber auch andere Anbieter:

- **Anthropic Claude** (API-Key + Base-URL)
- **Google Gemini**
- **Lokale Modelle** via Ollama, LM Studio, LocalAI
- **OpenRouter** als Meta-Provider

**Umsetzung:** Ein neues Config-Feld `provider` (enum: `openai`, `anthropic`, `ollama`, `custom`) und je nach Auswahl die passenden Env-Variablen setzen. Das `openai_base_url`-Feld existiert bereits und deckt kompatible APIs ab, aber eine explizite Provider-Auswahl waere benutzerfreundlicher.

---

## 2. Persistente Konversations-History

**Status:** Idee
**Aufwand:** Mittel

Beim Neustart des Containers geht der gesamte Chat-Verlauf verloren.

- Konversationen in `/data/history/` oder `/addon_configs/` persistent speichern
- Beim Start die letzte Session optional wiederherstellen
- Config-Option `persist_history` (bool) und `max_history_size` (MB)

---

## 3. Home-Assistant-Entity-Zugriff direkt aus Codex

**Status:** Idee
**Aufwand:** Hoch

Die eigentliche Killer-Feature-Idee: Codex koennte direkt mit Home Assistant interagieren.

- Ein kleines CLI-Tool `/usr/local/bin/ha-query` im Container bereitstellen
- Nutzt die HA Supervisor-API (`http://supervisor/core/api/...`)
- Codex kann dann z.B. gefragt werden: *"Schalte das Licht im Wohnzimmer ein"*
- Das Tool wuerde `ha-query states`, `ha-query call_service light.turn_on ...` unterstuetzen
- Supervisor-Token ist im Container ueber `$SUPERVISOR_TOKEN` verfuegbar

**Beispiel-Workflow:**
```
User: "Zeige mir alle Lichter die gerade an sind"
Codex: fuehrt `ha-query states --domain light --state on` aus
Codex: "Folgende 3 Lichter sind an: ..."
```

---

## 4. Automatische Updates des Codex CLI

**Status:** Idee
**Aufwand:** Niedrig

- Beim Container-Start pruefen ob eine neuere Version von `@openai/codex` verfuegbar ist
- Config-Option `auto_update_codex` (bool, default: false)
- `npm update -g @openai/codex` beim Start ausfuehren wenn aktiviert

---

## 5. Datei-Browser / Upload-Funktion

**Status:** Idee
**Aufwand:** Mittel

Nutzer moechten manchmal Dateien in den Workspace hochladen oder herunterladen, ohne SSH.

- Einen einfachen Datei-Browser als zweiten Service (z.B. `filebrowser` oder ein minimales Node-basiertes Tool)
- Erreichbar ueber einen separaten Ingress-Pfad oder Tab
- Alternative: Ein `upload.sh`-Script das ueber ttyd eine einfache Upload-Moeglichkeit bietet

---

## 6. Vordefinierte Prompts / Prompt-Bibliothek

**Status:** Idee
**Aufwand:** Niedrig

- YAML-Datei mit vordefinierten Prompts fuer haeufige HA-Aufgaben:
  - "Erstelle eine Automation fuer ..."
  - "Erklaere diese YAML-Konfiguration"
  - "Finde Fehler in meiner configuration.yaml"
  - "Erstelle ein Dashboard-Card fuer ..."
- Auswaehlbar ueber ein kleines Wrapper-Script oder Alias-Befehle
- Nutzer koennen eigene Prompts in `/addon_configs/chatgpt_codex/prompts.yaml` ablegen

---

## 7. Multi-User / Authentifizierung

**Status:** Idee
**Aufwand:** Hoch

- Verschiedene HA-Benutzer koennten eigene API-Keys und separate Sessions haben
- Pro-User-Konfiguration ueber HA User-Context (Ingress leitet HA-User-Info weiter)
- Getrennte Workspace-Verzeichnisse pro User

---

## 8. Ressourcen-Monitoring

**Status:** Idee
**Aufwand:** Niedrig

- CPU- und RAM-Verbrauch des Codex-Prozesses anzeigen
- Token-Verbrauch pro Session tracken (sofern die API das zurueckgibt)
- Einfaches Dashboard oder Sensor-Entity in HA exponieren
- Kostenabschaetzung basierend auf Token-Verbrauch

---

## 9. Notification-Integration

**Status:** Idee
**Aufwand:** Mittel

- Wenn ein laenger laufender Codex-Task fertig ist, eine HA-Notification senden
- Nutzt `ha notify` oder die Supervisor-API
- Nuetzlich wenn Codex im Hintergrund groessere Aufgaben bearbeitet

---

## 10. SSH-Key-Management

**Status:** Idee
**Aufwand:** Niedrig

- SSH-Keys im Container konfigurierbar machen fuer Git-Operationen
- Config-Option um einen vorhandenen SSH-Key aus `/ssl/` zu mounten
- Codex kann dann direkt mit privaten Git-Repos arbeiten

---

## 11. Backup & Restore der Codex-Konfiguration

**Status:** Idee
**Aufwand:** Niedrig

- `.codex/`-Konfiguration und History in HA-Backups einbeziehen
- Snapshot-Funktion fuer den aktuellen Workspace-Stand
- Integration mit HA's eigenem Backup-System

---

## 12. Terminal-Multiplexing (tmux/screen)

**Status:** Idee
**Aufwand:** Niedrig

- `tmux` im Container vorinstallieren
- Mehrere Terminal-Panes in einer Session ermoeglichen
- Ein Pane fuer Codex, ein anderes fuer manuelle Shell-Befehle
- Persistente tmux-Sessions die Container-Neustarts ueberleben (via tmux-resurrect)

---

## 13. Web-UI Erweiterung

**Status:** Idee
**Aufwand:** Hoch

Statt nur ein rohes Terminal anzuzeigen, ein Wrapper-UI bauen:

- Chat-aehnliche Oberflaeche (wie ChatGPT) statt Terminal
- Syntax-Highlighting fuer Code-Bloecke
- Copy-Button fuer generierte Code-Snippets
- Split-View: Chat links, Datei-Editor rechts
- Basierend auf einem leichtgewichtigen Framework (Preact/Alpine.js)

---

## 14. Git-Integration

**Status:** Idee
**Aufwand:** Mittel

- Automatisches Git-Init im Workspace
- Codex-generierte Aenderungen automatisch committen
- Diff-Ansicht bevor Aenderungen angewendet werden
- Integration mit GitHub/GitLab fuer Remote-Repos

---

## Priorisierungs-Vorschlag

| Prio | Feature | Begruendung |
|------|---------|-------------|
| 1    | #3 HA-Entity-Zugriff | Groesster Mehrwert fuer HA-Nutzer |
| 2    | #6 Prompt-Bibliothek | Schnell umsetzbar, hoher Nutzen |
| 3    | #4 Auto-Update Codex | Einfach, reduziert Wartung |
| 4    | #2 Persistente History | Oft gewuenscht, verbessert UX |
| 5    | #1 Mehrere Provider | Erweitert die Zielgruppe |
| 6    | #10 SSH-Key-Management | Wichtig fuer Git-Workflows |
| 7    | #8 Ressourcen-Monitoring | Kostenkontrolle |
| 8    | #12 tmux | Power-User Feature |
| 9    | #13 Web-UI | Groesster Aufwand, groesster UX-Sprung |
