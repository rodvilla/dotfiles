# Opencode Config

## My Providers
I currently have subscriptions with 3 providers:
- Github Copilot Pro+
- Opencode Zen (no billing, free models only)
- Opencode Go

## Oh-my-openagent Model Management
Model assignments for all OMO agents and categories are managed via the `/omo-models` command.

- `/omo-models` or `/omo-models standard` — Mixed providers (default). Best model per role across copilot + opencode-go. Uses opencode-go for planning agents needing large context (Prometheus, Metis, Atlas) and copilot for everything else.
- `/omo-models opencode` — All opencode-go models. Kimi K2.5 for orchestration/planning, GLM-5 for reasoning, MiniMax M2.7 for utility.
- `/omo-models copilot` — All github-copilot models. GPT-5.4 for planning (larger context than Claude on Copilot), Opus 4.6 for orchestration, Grok for search.
- `/omo-models --show` — Display current config without changes.

The preset definitions live in `~/.config/opencode/commands/omo-models.md`. Update them there when new models come out.


