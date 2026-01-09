# Caly 📅 — macOS calendar wizard CLI + MCP server

![Caly](Assets/logo.png)

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white&style=flat-square)](https://swift.org/)
[![macOS 13+](https://img.shields.io/badge/macOS-13+-0078d7?logo=apple&logoColor=white&style=flat-square)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-ffd60a?style=flat-square)](https://opensource.org/licenses/MIT)
[![MCP Server](https://img.shields.io/badge/MCP-Server-2ea44f?style=flat-square)](https://modelcontextprotocol.io/)

Caly brings calendar automation to macOS through a Swift CLI and MCP server. Read, search, and create Calendar.app events via EventKit — from the terminal or any MCP client.

## What you get

| Feature | Description |
|---------|-------------|
| **List Events** | Upcoming events with human or JSON output |
| **Search Events** | Find events by keyword across date ranges |
| **List Calendars** | Enumerate all available calendars |
| **Create Events** | Add new events with title, dates, calendar |
| **MCP Server** | All features exposed as MCP tools for AI agents |

## Install

```bash
# Clone and build
git clone https://github.com/RyanLisse/Caly.git
cd Caly
swift build -c release

# Install to PATH
cp .build/release/caly /usr/local/bin/caly
```

## Quick start

```bash
# List upcoming events
caly list --days 7

# List with JSON output
caly list --from 2026-01-01 --to 2026-01-07 --json

# Search events
caly search "standup" --days 30

# List calendars
caly calendars

# Create an event
caly create "Team Meeting" \
  --start 2026-01-04T10:00:00Z \
  --end 2026-01-04T10:30:00Z \
  --calendar "Work"
```

| Command | Key flags | What it does |
|---------|-----------|--------------|
| `list` | `--days`, `--from/--to`, `--json` | List calendar events for a period |
| `search` | `<query>`, `--days`, `--json` | Search events by keyword |
| `calendars` | `--json` | List available calendars |
| `create` | `--start`, `--end`, `--calendar` | Create a new event |

## MCP Server

The Bun-based MCP server shells out to the `caly` CLI.

```bash
# Ensure caly is on PATH first
cd mcp-server
bun install
bun run index.ts
```

### MCP Tools

| Tool | Description |
|------|-------------|
| `caly_list` | List calendar events for a period |
| `caly_search` | Search calendar events by keyword |
| `caly_calendars` | List available calendars |
| `caly_create` | Create a new event |

### Claude Desktop Config

```json
{
  "mcpServers": {
    "caly": {
      "command": "bun",
      "args": ["run", "/path/to/Caly/mcp-server/index.ts"]
    }
  }
}
```

## Architecture

Follows the [Peekaboo](https://github.com/steipete/Peekaboo) architecture standard:

```
Sources/
├── Core/           # Framework-agnostic library (no CLI deps)
│   ├── Models/     # CalendarEventOutput, CalendarOutput, ResultOutput<T>
│   ├── Services/   # CalendarManager (actor-based EventKit wrapper)
│   └── Exports.swift
├── CLI/            # Commander subcommands
│   ├── Commands/   # ListCommand, SearchCommand, CalendarsCommand, CreateCommand
│   └── CalyCLI.swift
├── MCP/            # MCP server (future Swift implementation)
└── Executable/     # Main entry point
```

## Requirements

- **macOS 13+** (Ventura or later)
- **Swift 6.0+** toolchain
- **Calendar permissions** (EventKit prompts on first run)
- **Bun** (for MCP server)

## Development

```bash
# Build
swift build

# Run CLI
swift run caly --help

# Test
swift test

# MCP server
cd mcp-server && bun run index.ts
```

### Swift 6 Settings

All targets use strict concurrency:

```swift
.enableExperimentalFeature("StrictConcurrency")
.enableUpcomingFeature("ExistentialAny")
.enableUpcomingFeature("NonisolatedNonsendingByDefault")
```

## Notes

- First run triggers macOS Calendar permission prompts
- Headless MCP clients may need manual permission grants
- Calendar matching is by name (not stable IDs)
- Legacy `Apps/CLI/` structure is deprecated

## License

MIT
