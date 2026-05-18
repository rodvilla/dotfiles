---
name: rn-logs-cli
description: Use when you need React Native Metro logs via the rn-logs CLI in non-interactive terminal sessions.
---

# RN Logs CLI

Use `rn-logs` to inspect React Native Metro logs through CDP with plain-text output.

## When To Use

- You need live logs from a running React Native app.
- You need low-overhead text logs suitable for agent runs.

## Setup

```bash
npm install -g rn-logs-cli
rn-logs --help
```

Requirements:

- Metro is running.
- At least one app is connected.

## Core Workflow

```bash
# List connected apps
rn-logs apps

# Stream logs for app
rn-logs logs --app "<id|name>"

# Snapshot recent logs
rn-logs logs --app "<id|name>" --limit 50
```

Host/port override:

```bash
rn-logs logs --app "<id|name>" --host "localhost" --port "8081"
```

## Common Errors

- `metro not reachable`: start Metro or fix host/port.
- `no apps connected`: launch app on simulator/device.
- `multiple apps connected`: pass explicit `--app`.
