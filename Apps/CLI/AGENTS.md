# Caly CLI (Swift) — Agent Guide

## Overview
Swift CLI (`caly`) built with `swift-argument-parser` and EventKit. Primary logic lives in a single file and centers around `CalendarManager`.

## Where To Look
- Commands + EventKit glue: `Apps/CLI/Sources/Caly/main.swift`
- SwiftPM manifest: `Apps/CLI/Package.swift`

## Conventions
- Keep commands `AsyncParsableCommand` and route all EventKit access through `CalendarManager`.
- Prefer ISO-8601 for date/time arguments (`--start`, `--end`) and keep date parsing consistent.
- `--json` output should use `ResultOutput<T>` wrappers and stable key ordering when possible.
- Calendar selection is by name match; avoid persisting identifiers.

## Gotchas
- First run requires Calendar permissions; failures should be surfaced clearly in both text and JSON modes.
- EventKit access differs by macOS version (`requestFullAccessToEvents` on macOS 14+).

## Anti-Patterns
- Don’t commit `Apps/CLI/.build/` or derived data.
- Don’t assume a particular calendar exists; default calendars vary by machine.

## Commands
```bash
cd Apps/CLI

# CLI help
swift run caly --help

# List events (next 7 days)
swift run caly list

# List events as JSON
swift run caly list --json

# Search events (next 30 days)
swift run caly search "standup"

# List calendars
swift run caly calendars

# Create an event
swift run caly create "My Event" --start 2026-01-04T10:00:00Z --end 2026-01-04T10:30:00Z
```
