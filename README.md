# Caly 🧙 — A macOS calendar wizard CLI + MCP server

![Caly](Assets/logo.png)

Caly is a small macOS calendar “wizard”:
- A Swift CLI (`caly`) that reads/writes Calendar.app events via EventKit
- A Bun/TypeScript MCP server (`caly-mcp`) that exposes the CLI as MCP tools

## What you get
- List upcoming events (human output or `--json`)
- Search events by keyword
- List calendars
- Create events
- Use all of the above from MCP clients by running `caly-mcp`

## Requirements
- macOS 13+
- Swift toolchain (SwiftPM)
- Calendar permissions (EventKit prompts on first run)
- For the MCP server: Bun

## Quick start (CLI)
```bash
cd Apps/CLI

# Run from sources
swift run caly --help

# Examples
swift run caly list --days 7
swift run caly list --from 2026-01-01 --to 2026-01-07 --json
swift run caly search "standup" --days 30
swift run caly calendars
swift run caly create "My Event" --start 2026-01-04T10:00:00Z --end 2026-01-04T10:30:00Z
```

## Quick start (MCP server)
The MCP server shells out to `caly` (it must be on your `PATH`).

```bash
# Build/install caly so `caly` is available on PATH
cd Apps/CLI
swift build -c release
cp .build/release/caly /usr/local/bin/caly

# Run the MCP server
cd ../../mcp-server
bun install
bun run index.ts
```

### Tools exposed
`caly-mcp` currently provides:
- `caly_list`: List calendar events for a period
- `caly_search`: Search calendar events by keyword
- `caly_calendars`: List available calendars
- `caly_create`: Create a new event

## Repository layout
```
./
├── Apps/CLI/            # Swift CLI app (caly)
├── mcp-server/          # Bun-based MCP server (caly-mcp)
└── Assets/              # icons/images used for packaging/docs
```

## Notes / gotchas
- The first run will trigger macOS Calendar permission prompts; headless MCP clients may need you to grant access manually.
- Calendar matching is by name; avoid relying on stable identifiers across machines.

## Development
```bash
# Swift CLI
cd Apps/CLI
swift run caly --help

# MCP server
cd mcp-server
bun install
bun run index.ts
```
