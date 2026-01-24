# ⚠️ DEPRECATED

This TypeScript/Bun MCP server is **deprecated**.

## Use Native Swift MCP Server Instead

```bash
# Start the native MCP server
caly mcp serve

# List available tools
caly mcp tools
```

## Claude Desktop Config (Updated)

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

## Why Deprecated?

1. **Performance:** Native Swift is faster than shelling out to CLI
2. **Consistency:** Single codebase in Swift
3. **Architecture:** Follows Peekaboo architecture standard
4. **Handler Pattern:** Proper separation of concerns

## Migration

1. Build Caly: `swift build -c release`
2. Install: `cp .build/release/caly /usr/local/bin/`
3. Update MCP config to use `caly mcp serve`
4. Remove TypeScript mcp-server references

---

*Deprecated as of 2026-01-09*
