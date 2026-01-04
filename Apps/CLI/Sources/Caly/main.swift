import ArgumentParser
import EventKit
import Foundation

@main
struct CalyCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "caly",
        abstract: "🧙 Caly: Your quirky calendar wizard CLI",
        subcommands: [List.self, Search.self, Calendars.self, Create.self],
        defaultSubcommand: List.self
    )
}

actor CalendarManager {
    static let shared = CalendarManager()
    private let store = EKEventStore()
    
    func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func getEvents(from startDate: Date, to endDate: Date, calendars: [String]? = nil) -> [EKEvent] {
        var calendarObjects: [EKCalendar]? = nil
        
        if let calendarNames = calendars, !calendarNames.isEmpty {
            calendarObjects = store.calendars(for: .event).filter { cal in
                calendarNames.contains { name in
                    cal.title.localizedCaseInsensitiveContains(name)
                }
            }
        }
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarObjects)
        return store.events(matching: predicate)
    }
    
    func searchEvents(query: String, from startDate: Date, to endDate: Date) -> [EKEvent] {
        let allEvents = getEvents(from: startDate, to: endDate)
        let lowercaseQuery = query.lowercased()
        
        return allEvents.filter { event in
            event.title?.lowercased().contains(lowercaseQuery) == true ||
            event.location?.lowercased().contains(lowercaseQuery) == true ||
            event.notes?.lowercased().contains(lowercaseQuery) == true
        }
    }
    
    func getAllCalendars() -> [EKCalendar] {
        return store.calendars(for: .event)
    }
    
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        isAllDay: Bool,
        calendarName: String?
    ) throws -> String {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.location = location
        event.notes = notes
        
        if let name = calendarName {
            if let calendar = store.calendars(for: .event).first(where: { 
                $0.title.localizedCaseInsensitiveContains(name) 
            }) {
                event.calendar = calendar
            } else {
                event.calendar = store.defaultCalendarForNewEvents
            }
        } else {
            event.calendar = store.defaultCalendarForNewEvents
        }
        
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier ?? "unknown"
    }
}

struct CalendarEventOutput: Codable {
    let id: String
    let title: String
    let location: String?
    let notes: String?
    let startDate: String
    let endDate: String
    let calendarName: String
    let calendarColor: String?
    let isAllDay: Bool
    let url: String?
}

struct CalendarOutput: Codable {
    let id: String
    let title: String
    let type: String
    let color: String?
    let source: String
    let isSubscribed: Bool
    let isImmutable: Bool
}

struct ResultOutput<T: Codable>: Codable {
    let success: Bool
    let count: Int
    let data: T
    let error: String?
}

extension EKEvent {
    func toOutput() -> CalendarEventOutput {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        return CalendarEventOutput(
            id: eventIdentifier ?? UUID().uuidString,
            title: title ?? "Untitled",
            location: location,
            notes: notes,
            startDate: startDate.map { formatter.string(from: $0) } ?? "",
            endDate: endDate.map { formatter.string(from: $0) } ?? "",
            calendarName: calendar?.title ?? "Unknown",
            calendarColor: calendar?.cgColor.map { colorToHex($0) },
            isAllDay: isAllDay,
            url: url?.absoluteString
        )
    }
}

extension EKCalendar {
    func toOutput() -> CalendarOutput {
        CalendarOutput(
            id: calendarIdentifier,
            title: title,
            type: calendarTypeString,
            color: cgColor.map { colorToHex($0) },
            source: source?.title ?? "Unknown",
            isSubscribed: type == .subscription,
            isImmutable: isImmutable
        )
    }
    
    var calendarTypeString: String {
        switch type {
        case .local: return "local"
        case .calDAV: return "caldav"
        case .exchange: return "exchange"
        case .subscription: return "subscription"
        case .birthday: return "birthday"
        @unknown default: return "unknown"
        }
    }
}

func colorToHex(_ cgColor: CGColor) -> String {
    guard let components = cgColor.components, components.count >= 3 else {
        return "#000000"
    }
    let r = Int(components[0] * 255)
    let g = Int(components[1] * 255)
    let b = Int(components[2] * 255)
    return String(format: "#%02X%02X%02X", r, g, b)
}

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "List calendar events")
    
    @Option(name: .shortAndLong) var days: Int = 7
    @Option var from: String?
    @Option var to: String?
    @Option(name: .shortAndLong) var limit: Int?
    @Option(name: .shortAndLong) var calendar: String?
    @Flag var includePast: Bool = false
    @Flag var json: Bool = false
    
    func run() async throws {
        let manager = CalendarManager.shared
        let granted = try await manager.requestAccess()
        
        if !granted {
            let result = ResultOutput(success: false, count: 0, data: [CalendarEventOutput](), error: "Access denied")
            if json { print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!) }
            else { print("Error: Access denied") }
            return
        }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let start = from.flatMap { df.date(from: $0) } ?? (includePast ? Calendar.current.startOfDay(for: Date()) : Date())
        let end = to.flatMap { df.date(from: $0) }.map { Calendar.current.date(byAdding: .day, value: 1, to: $0)! } ?? Calendar.current.date(byAdding: .day, value: days, to: start)!
        
        let filters = calendar?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        var events = await manager.getEvents(from: start, to: end, calendars: filters)
        if let limit = limit { events = Array(events.prefix(limit)) }
        
        let outputs = events.map { $0.toOutput() }
        if json {
            let result = ResultOutput(success: true, count: outputs.count, data: outputs, error: nil)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            print(String(data: try encoder.encode(result), encoding: .utf8)!)
        } else {
            for e in outputs { print("[\(e.calendarName)] \(e.title)\n  When: \(e.startDate)\n") }
        }
    }
}

struct Search: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Search calendar events")
    @Argument var query: String
    @Option(name: .shortAndLong) var days: Int = 30
    @Flag var json: Bool = false
    
    func run() async throws {
        let manager = CalendarManager.shared
        let granted = try await manager.requestAccess()
        if !granted { return }
        
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: days, to: start)!
        let events = await manager.searchEvents(query: query, from: start, to: end)
        let outputs = events.map { $0.toOutput() }
        
        if json {
            let result = ResultOutput(success: true, count: outputs.count, data: outputs, error: nil)
            print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!)
        } else {
            for e in outputs { print("[\(e.calendarName)] \(e.title)") }
        }
    }
}

struct Calendars: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "List calendars")
    @Flag var json: Bool = false
    func run() async throws {
        let manager = CalendarManager.shared
        if try await !manager.requestAccess() { return }
        let cals = await manager.getAllCalendars().map { $0.toOutput() }
        if json {
            let result = ResultOutput(success: true, count: cals.count, data: cals, error: nil)
            print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!)
        } else {
            for c in cals { print("- \(c.title) [\(c.type)]") }
        }
    }
}

struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Create event")
    @Argument var title: String
    @Option var start: String
    @Option var end: String
    @Option var calendar: String?
    @Flag var allDay: Bool = false
    func run() async throws {
        let manager = CalendarManager.shared
        if try await !manager.requestAccess() { return }
        let iso = ISO8601DateFormatter()
        guard let s = iso.date(from: start), let e = iso.date(from: end) else { return }
        let id = try await manager.createEvent(title: title, startDate: s, endDate: e, location: nil, notes: nil, isAllDay: allDay, calendarName: calendar)
        print("Created: \(id)")
    }
}
