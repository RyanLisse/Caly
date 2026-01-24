import ArgumentParser
import CalyCore
import Foundation

struct MCPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp",
        abstract: "MCP server operations",
        subcommands: [Serve.self, ListMCPTools.self],
        defaultSubcommand: Serve.self
    )

    struct Serve: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "serve",
            abstract: "Start the MCP server (stdio transport)"
        )

        mutating func run() async throws {
            let server = CalyMCPServer()
            try await server.run()
        }
    }

    struct ListMCPTools: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "tools",
            abstract: "List available MCP tools"
        )

        func run() throws {
            print("Available MCP Tools for Caly:")
            print("")
            print("📅 caly_list")
            print("   List calendar events for a given period")
            print("   Parameters:")
            print("   - days: Number of days to look ahead (default 7)")
            print("   - from: Start date (YYYY-MM-DD)")
            print("   - to: End date (YYYY-MM-DD)")
            print("   - limit: Maximum number of events")
            print("   - calendar: Filter by calendar name")
            print("   - includePast: Include past events from today")
            print("")
            print("🔍 caly_search")
            print("   Search calendar events by keyword")
            print("   Parameters:")
            print("   - query: Search term (required)")
            print("   - days: Number of days to search (default 30)")
            print("")
            print("📚 caly_calendars")
            print("   List all available calendars")
            print("")
            print("➕ caly_create")
            print("   Create a new calendar event")
            print("   Parameters:")
            print("   - title: Event title (required)")
            print("   - start: Start date/time ISO 8601 (required)")
            print("   - end: End date/time ISO 8601 (required)")
            print("   - calendar: Calendar name")
            print("   - location: Event location")
            print("   - notes: Event notes")
            print("   - allDay: All-day event flag")
        }
    }
}
