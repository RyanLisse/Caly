# Repository Guidelines

## Start Here
- Read `~/Projects/agent-scripts/{AGENTS.MD,TOOLS.MD}` before making changes (skip if missing).
- This repo follows the Peekaboo architecture pattern.

## Project Structure & Modules
- `Sources/Core/` contains the framework-agnostic `CalyCore` library (EventKit integration, models, services).
- `Sources/CLI/` contains the Swift CLI using ArgumentParser.
- `Sources/MCP/` will contain the Swift-based MCP server (future).
- `mcp-server/` hosts the current Bun-based MCP server that shells to the CLI.
- Legacy `Apps/CLI/` structure is deprecated; use new `Sources/` layout.

## Build, Test, and Development Commands
- Build: `swift build` (debug) or `swift build -c release` (release)
- Run CLI: `swift run caly --help`
- Test: `swift test`
- MCP server: `cd mcp-server && bun run index.ts`

## Coding Style & Naming Conventions
- Swift 6.0, 4-space indent, 120-column wrap
- Strict concurrency enabled across all targets
- Prefer small scoped extensions over large files
- Actor-based services (e.g., `CalendarManager`)

## Swift 6 Settings
All targets use:
```swift
.enableExperimentalFeature("StrictConcurrency")
.enableUpcomingFeature("ExistentialAny")
.enableUpcomingFeature("NonisolatedNonsendingByDefault")
```

## Architecture Patterns
- **Core library**: Framework-agnostic, no CLI dependencies
- **Handler pattern**: Separate handlers for different tool types
- **Actor-based services**: Thread-safe EventKit access
- **ResultOutput<T>**: Generic wrapper for JSON/human output

## Reference Patterns
- Peekaboo: `/Volumes/Main SSD/Developer/Peekaboo/`
- Quorum: `/Users/shelton/Developer/Quorum/`
- Handler pattern from: `cameroncooke/reloaderoo`

## Testing Guidelines
- Add tests in `Tests/` directory
- Use XCTest with async/await
- Mock EventKit where possible

## Commit & Pull Request Guidelines
- Conventional Commits (`feat|fix|chore|docs|test|refactor`)
- Scope optional: `feat(cli): add event filtering`
- PRs should summarize intent and list test commands

## Security & Configuration
- Never commit credentials
- Calendar permissions managed by macOS
- Respect user calendar privacy
