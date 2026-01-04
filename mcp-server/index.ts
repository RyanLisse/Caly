import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";

const server = new Server(
  {
    name: "caly-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const CALY_PATH = "caly"; 

function runCaly(args: string) {
  try {
    const output = execSync(`${CALY_PATH} ${args}`, { encoding: "utf-8" });
    return output;
  } catch (error: any) {
    return `Error: ${error.message}\n${error.stderr || ""}`;
  }
}

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "caly_list",
        description: "🧙 List calendar events for a given period",
        inputSchema: {
          type: "object",
          properties: {
            days: { type: "number", description: "Number of days to look ahead (default 7)" },
            from: { type: "string", description: "Start date (YYYY-MM-DD)" },
            to: { type: "string", description: "End date (YYYY-MM-DD)" },
            limit: { type: "number", description: "Maximum number of events" },
            calendar: { type: "string", description: "Filter by calendar name" },
            includePast: { type: "boolean", description: "Include past events from today" },
          },
        },
      },
      {
        name: "caly_search",
        description: "🧙 Search calendar events by keyword",
        inputSchema: {
          type: "object",
          properties: {
            query: { type: "string", description: "Search term" },
            days: { type: "number", description: "Number of days to search (default 30)" },
          },
          required: ["query"],
        },
      },
      {
        name: "caly_calendars",
        description: "🧙 List all available calendars",
        inputSchema: { type: "object", properties: {} },
      },
      {
        name: "caly_create",
        description: "🧙 Create a new calendar event",
        inputSchema: {
          type: "object",
          properties: {
            title: { type: "string" },
            start: { type: "string", description: "Start date/time (ISO 8601)" },
            end: { type: "string", description: "End date/time (ISO 8601)" },
            calendar: { type: "string", description: "Calendar name" },
            allDay: { type: "boolean" },
          },
          required: ["title", "start", "end"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "caly_list": {
      const { days, from, to, limit, calendar, includePast } = args as any;
      let cmd = "list";
      if (days) cmd += ` --days ${days}`;
      if (from) cmd += ` --from ${from}`;
      if (to) cmd += ` --to ${to}`;
      if (limit) cmd += ` --limit ${limit}`;
      if (calendar) cmd += ` --calendar "${calendar}"`;
      if (includePast) cmd += " --include-past";
      return { content: [{ type: "text", text: runCaly(cmd) }] };
    }
    case "caly_search": {
      const { query, days } = args as any;
      let cmd = `search "${query}"`;
      if (days) cmd += ` --days ${days}`;
      return { content: [{ type: "text", text: runCaly(cmd) }] };
    }
    case "caly_calendars": {
      return { content: [{ type: "text", text: runCaly("calendars") }] };
    }
    case "caly_create": {
      const { title, start, end, calendar, allDay } = args as any;
      let cmd = `create "${title}" --start ${start} --end ${end}`;
      if (calendar) cmd += ` --calendar "${calendar}"`;
      if (allDay) cmd += " --all-day";
      return { content: [{ type: "text", text: runCaly(cmd) }] };
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
