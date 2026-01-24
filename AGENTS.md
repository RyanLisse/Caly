READ ~/Developer/agent-scripts/AGENTS.MD BEFORE ANYTHING (skip if missing)

# Caly — Agent Guide

## Overview
Caly is a macOS calendar CLI + native Swift MCP server. Uses EventKit for calendar operations.

## Architecture (Peekaboo Standard)
```
Sources/
├── Core/                    # Framework-agnostic library
│   ├── Models/              # CalendarEventOutput, CalendarOutput, ResultOutput<T>
│   ├── Services/            # CalendarManager (actor)
│   └── Exports.swift
├── CLI/                     # CLI interface
│   ├── Commands/            # ListCommand, SearchCommand, CalendarsCommand, CreateCommand, MCPCommand
│   ├── MCP/                 # Native Swift MCP server
│   │   ├── CalyMCPServer.swift
│   │   └── handlers/
│   │       └── CalyToolHandler.swift
│   └── CalyCLI.swift
```

## Key Files
| File | Purpose |
|------|---------|
| `Sources/Core/Services/CalendarManager.swift` | EventKit wrapper (actor) |
| `Sources/Core/Models/CalendarModels.swift` | Data models |
| `Sources/CLI/MCP/CalyMCPServer.swift` | MCP server entry |
| `Sources/CLI/MCP/handlers/CalyToolHandler.swift` | MCP tool handler (handler pattern) |

## Patterns Used
- **Handler Pattern:** CalyToolHandler handles all MCP tools
- **Actor Pattern:** CalendarManager and CalyMCPServer are actors
- **Config Priority:** CLI args > env vars > defaults
- **Swift 6:** StrictConcurrency, ExistentialAny, NonisolatedNonsendingByDefault

## MCP Tools
- `caly_list` - List calendar events
- `caly_search` - Search events by keyword
- `caly_calendars` - List calendars
- `caly_create` - Create new event

## Common Commands
```bash
# Build
swift build

# Run CLI
swift run caly list --days 7
swift run caly search "meeting"
swift run caly calendars
swift run caly create "Event" --start 2026-01-10T10:00:00Z --end 2026-01-10T11:00:00Z

# Run MCP server
swift run caly mcp serve

# List MCP tools
swift run caly mcp tools
```

## Deprecated
- `mcp-server/` - TypeScript/Bun MCP server (use `caly mcp serve` instead)
- `Apps/CLI/` - Old CLI structure (use `Sources/CLI/` instead)

## Notes
- EventKit requires calendar permissions (TCC)
- First run triggers macOS permission prompts
- Calendar matching is by name (not stable IDs)
