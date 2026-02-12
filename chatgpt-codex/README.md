# Home Assistant Add-on: ChatGPT Codex

Run the OpenAI Codex CLI inside Home Assistant through a browser terminal (ttyd).

## Features

- Browser-based shell on port `7681`
- Codex CLI pre-installed
- Optional `OPENAI_API_KEY` and `OPENAI_BASE_URL`
- Configurable workspace path and custom Codex arguments

## Options

```yaml
openai_api_key: ""
openai_base_url: ""
codex_args: ""
workspace: /share
```

## Usage

1. Set your `openai_api_key` in the add-on options.
2. Start the add-on.
3. Open `http://<home-assistant-host>:7681`.
4. Use Codex from the terminal.

## Notes

- The add-on starts Codex in the configured `workspace` directory.
- Keep API keys in add-on options, not in scripts checked into Git.
