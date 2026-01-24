# Caly 📅 — macOS calendar wizard CLI + MCP server

![Caly](Assets/logo.png)

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white&style=flat-square)](https://swift.org/)
[![macOS 13+](https://img.shields.io/badge/macOS-13+-0078d7?logo=apple&logoColor=white&style=flat-square)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-ffd60a?style=flat-square)](https://opensource.org/licenses/MIT)
[![MCP Server](https://img.shields.io/badge/MCP-Server-2ea44f?style=flat-square)](https://modelcontextprotocol.io/)

Caly brings calendar automation to macOS through a Swift CLI and native MCP server. Read, search, and create Calendar.app events via EventKit — from the terminal or any MCP client.

## What you get

| Feature | Description |
|---------|-------------|
| **List Events** | Upcoming events with human or JSON output |
| **Search Events** | Find events by keyword across date ranges |
| **List Calendars** | Enumerate all available calendars |
| **Create Events** | Add new events with title, dates, calendar |
| **MCP Server** | Native Swift MCP server for AI agents |

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
| `mcp serve` | — | Start native MCP server |
| `mcp tools` | — | List available MCP tools |

## MCP Server

Native Swift MCP server using [swift-sdk](https://github.com/modelcontextprotocol/swift-sdk):

```bash
# Start MCP server (stdio transport)
caly mcp serve

# List available tools
caly mcp tools
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
      "command": "caly",
      "args": ["mcp", "serve"]
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
│   ├── Commands/   # ListCommand, SearchCommand, CalendarsCommand, CreateCommand, MCPCommand
│   ├── MCP/        # Native Swift MCP server
│   │   ├── CalyMCPServer.swift
│   │   └── handlers/
│   │       └── CalyToolHandler.swift
│   └── CalyCLI.swift
```

### Handler Pattern

MCP tools are handled by `CalyToolHandler` actor:

```swift
public actor CalyToolHandler {
    public func listTools() -> ListTools.Result
    public func callTool(_ params: CallTool.Parameters) async throws -> CallTool.Result
}
```

## Requirements

- **macOS 13+** (Ventura or later)
- **Swift 6.0+** toolchain
- **Calendar permissions** (EventKit prompts on first run)

## Development

```bash
# Build
swift build

# Run CLI
swift run caly --help

# Run MCP server
swift run caly mcp serve

# Test
swift test
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
- Legacy `mcp-server/` (TypeScript) is deprecated — use native `caly mcp serve`

## License

MIT
