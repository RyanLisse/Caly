import CalyCore
import Foundation
import Logging
import MCP

/// Handler for Caly MCP tools following the handler pattern
public actor CalyToolHandler {
    private let logger: Logger
    private let calendarManager: CalendarManager

    public init(logger: Logger) {
        self.logger = logger
        self.calendarManager = CalendarManager.shared
    }

    // MARK: - Tool Listing

    public func listTools() -> ListTools.Result {
        ListTools.Result(tools: Self.allTools)
    }

    // MARK: - Tool Execution

    public func callTool(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        logger.info("Calling tool: \(params.name)")

        switch params.name {
        case "caly_list":
            return try await handleList(params.arguments)
        case "caly_search":
            return try await handleSearch(params.arguments)
        case "caly_calendars":
            return try await handleCalendars()
        case "caly_create":
            return try await handleCreate(params.arguments)
        default:
            throw CalyMCPError.methodNotFound("Unknown tool: \(params.name)")
        }
    }

    // MARK: - Tool Handlers

    private func handleList(_ args: [String: Value]?) async throws -> CallTool.Result {
        let granted = try await calendarManager.requestAccess()
        if !granted {
            return CallTool.Result(content: [.text("{\"success\": false, \"error\": \"Calendar access denied\"}")])
        }

        let days = args?["days"]?.intValue ?? 7
        let fromStr = args?["from"]?.stringValue
        let toStr = args?["to"]?.stringValue
        let limit = args?["limit"]?.intValue
        let calendarFilter = args?["calendar"]?.stringValue
        let includePast = args?["includePast"]?.boolValue ?? false

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let start = fromStr.flatMap { df.date(from: $0) }
            ?? (includePast ? Calendar.current.startOfDay(for: Date()) : Date())
        let end = toStr.flatMap { df.date(from: $0) }.map { Calendar.current.date(byAdding: .day, value: 1, to: $0)! }
            ?? Calendar.current.date(byAdding: .day, value: days, to: start)!

        let filters = calendarFilter?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        var events = await calendarManager.getEvents(from: start, to: end, calendars: filters)

        if let limit = limit {
            events = Array(events.prefix(limit))
        }

        let result = ResultOutput(success: true, count: events.count, data: events, error: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = String(data: try encoder.encode(result), encoding: .utf8) ?? "{}"

        return CallTool.Result(content: [.text(json)])
    }

    private func handleSearch(_ args: [String: Value]?) async throws -> CallTool.Result {
        guard let query = args?["query"]?.stringValue else {
            throw CalyMCPError.invalidParams("Missing required 'query' parameter")
        }

        let granted = try await calendarManager.requestAccess()
        if !granted {
            return CallTool.Result(content: [.text("{\"success\": false, \"error\": \"Calendar access denied\"}")])
        }

        let days = args?["days"]?.intValue ?? 30
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: days, to: start)!

        let events = await calendarManager.searchEvents(query: query, from: start, to: end)
        let result = ResultOutput(success: true, count: events.count, data: events, error: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = String(data: try encoder.encode(result), encoding: .utf8) ?? "{}"

        return CallTool.Result(content: [.text(json)])
    }

    private func handleCalendars() async throws -> CallTool.Result {
        let granted = try await calendarManager.requestAccess()
        if !granted {
            return CallTool.Result(content: [.text("{\"success\": false, \"error\": \"Calendar access denied\"}")])
        }

        let calendars = await calendarManager.getAllCalendars()
        let result = ResultOutput(success: true, count: calendars.count, data: calendars, error: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = String(data: try encoder.encode(result), encoding: .utf8) ?? "{}"

        return CallTool.Result(content: [.text(json)])
    }

    private func handleCreate(_ args: [String: Value]?) async throws -> CallTool.Result {
        guard let title = args?["title"]?.stringValue else {
            throw CalyMCPError.invalidParams("Missing required 'title' parameter")
        }
        guard let startStr = args?["start"]?.stringValue else {
            throw CalyMCPError.invalidParams("Missing required 'start' parameter")
        }
        guard let endStr = args?["end"]?.stringValue else {
            throw CalyMCPError.invalidParams("Missing required 'end' parameter")
        }

        let granted = try await calendarManager.requestAccess()
        if !granted {
            return CallTool.Result(content: [.text("{\"success\": false, \"error\": \"Calendar access denied\"}")])
        }

        let iso = ISO8601DateFormatter()
        guard let startDate = iso.date(from: startStr) else {
            throw CalyMCPError.invalidParams("Invalid 'start' date format. Use ISO8601.")
        }
        guard let endDate = iso.date(from: endStr) else {
            throw CalyMCPError.invalidParams("Invalid 'end' date format. Use ISO8601.")
        }

        let calendarName = args?["calendar"]?.stringValue
        let allDay = args?["allDay"]?.boolValue ?? false
        let location = args?["location"]?.stringValue
        let notes = args?["notes"]?.stringValue

        do {
            let eventId = try await calendarManager.createEvent(
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: location,
                notes: notes,
                isAllDay: allDay,
                calendarName: calendarName
            )
            return CallTool.Result(content: [.text("{\"success\": true, \"eventId\": \"\(eventId)\"}")])
        } catch {
            return CallTool.Result(content: [.text("{\"success\": false, \"error\": \"\(error.localizedDescription)\"}")])
        }
    }
}

// MARK: - Tool Definitions

extension CalyToolHandler {
    static let allTools: [Tool] = [
        Tool(
            name: "caly_list",
            description: "🧙 List calendar events for a given period",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "days": .object([
                        "type": "number",
                        "description": "Number of days to look ahead (default 7)"
                    ]),
                    "from": .object([
                        "type": "string",
                        "description": "Start date (YYYY-MM-DD)"
                    ]),
                    "to": .object([
                        "type": "string",
                        "description": "End date (YYYY-MM-DD)"
                    ]),
                    "limit": .object([
                        "type": "number",
                        "description": "Maximum number of events"
                    ]),
                    "calendar": .object([
                        "type": "string",
                        "description": "Filter by calendar name (comma-separated for multiple)"
                    ]),
                    "includePast": .object([
                        "type": "boolean",
                        "description": "Include past events from today"
                    ])
                ])
            ])
        ),
        Tool(
            name: "caly_search",
            description: "🧙 Search calendar events by keyword",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "query": .object([
                        "type": "string",
                        "description": "Search term"
                    ]),
                    "days": .object([
                        "type": "number",
                        "description": "Number of days to search (default 30)"
                    ])
                ]),
                "required": .array(["query"])
            ])
        ),
        Tool(
            name: "caly_calendars",
            description: "🧙 List all available calendars",
            inputSchema: .object([
                "type": "object",
                "properties": .object([:])
            ])
        ),
        Tool(
            name: "caly_create",
            description: "🧙 Create a new calendar event",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "title": .object([
                        "type": "string",
                        "description": "Event title"
                    ]),
                    "start": .object([
                        "type": "string",
                        "description": "Start date/time (ISO 8601)"
                    ]),
                    "end": .object([
                        "type": "string",
                        "description": "End date/time (ISO 8601)"
                    ]),
                    "calendar": .object([
                        "type": "string",
                        "description": "Calendar name"
                    ]),
                    "location": .object([
                        "type": "string",
                        "description": "Event location"
                    ]),
                    "notes": .object([
                        "type": "string",
                        "description": "Event notes"
                    ]),
                    "allDay": .object([
                        "type": "boolean",
                        "description": "All-day event"
                    ])
                ]),
                "required": .array(["title", "start", "end"])
            ])
        )
    ]
}

// MARK: - Value Extensions

extension Value {
    var intValue: Int? {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        case .string(let s): return Int(s)
        default: return nil
        }
    }

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }
}

// MARK: - Errors

public enum CalyMCPError: Error, LocalizedError {
    case methodNotFound(String)
    case invalidParams(String)
    case internalError(String)

    public var errorDescription: String? {
        switch self {
        case .methodNotFound(let msg): return "Method not found: \(msg)"
        case .invalidParams(let msg): return "Invalid parameters: \(msg)"
        case .internalError(let msg): return "Internal error: \(msg)"
        }
    }
}
