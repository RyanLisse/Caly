# Caly MCP Server (Bun/TypeScript) — Agent Guide

## Overview
`caly-mcp` is a Bun-first MCP server that exposes the local `caly` CLI as MCP tools over stdio.

## Where To Look
- MCP server entrypoint: `mcp-server/index.ts`
- Shebang wrapper for running via Bun: `mcp-server/bin.ts`
- Package + scripts: `mcp-server/package.json`

## Conventions
- Keep the server ESM (`"type": "module"`) and runnable via Bun.
- Tool schemas are defined in `ListToolsRequestSchema`; keep them strict and documented.
- The server shells out to `caly` (default: `caly` on PATH). Avoid hardcoding user-specific paths.
- Prefer returning actionable error text from tool calls; do not swallow stderr.

## Gotchas
- `caly` triggers macOS Calendar permission prompts; MCP clients may run headless.
- The server should not assume access to a GUI session.

## Anti-Patterns
- Don’t add Node-only patterns (e.g. Express servers) or require `npm`/`pnpm`.
- Don’t log secrets or include `.env`/credentials in the repo.

## Commands
```bash
cd mcp-server

# Install deps
bun install

# Run the MCP server (stdio)
bun run index.ts

# Or run the shebang wrapper
./bin.ts
```
