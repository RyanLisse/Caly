# Caly — Agent Guide

## Overview
Caly is a macOS calendar “wizard” CLI (Swift/EventKit) plus a companion MCP server (TypeScript/Bun) that exposes the CLI as MCP tools.

## Repository Layout
```
./
├── Apps/CLI/            # Swift CLI app (caly)
├── mcp-server/          # Bun-based MCP server (caly-mcp)
└── Assets/              # icons/images used for packaging/docs
```

## Where To Look
- CLI entrypoint + EventKit integration: `Apps/CLI/Sources/Caly/main.swift`
- MCP tool definitions + CLI invocation: `mcp-server/index.ts`
- MCP entrypoint wrapper (shebang): `mcp-server/bin.ts`

## Conventions (Project-Specific)
- CLI is async-first: commands conform to `AsyncParsableCommand` and call into `CalendarManager` actor.
- Calendar output supports both human output and JSON (`--json`) via `ResultOutput<T>`.
- MCP server is Bun-first and ESM (`"type": "module"`). Prefer Bun-native patterns.

## Anti-Patterns
- Don’t check in Swift build artifacts from `Apps/CLI/.build/`.
- Don’t hardcode user-specific calendar/event identifiers in code or docs.
- Don’t assume a GUI session exists when running the MCP server (it shells out to `caly`).

## Subdirectory Guides
- CLI-specific guidance: `Apps/CLI/AGENTS.md`
- MCP-server-specific guidance: `mcp-server/AGENTS.md`

## Common Commands
```bash
# Swift CLI
swift --version
cd Apps/CLI
swift run caly --help

# MCP server
cd mcp-server
bun install
bun run index.ts
```
