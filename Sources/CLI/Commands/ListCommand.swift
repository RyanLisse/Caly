import ArgumentParser
import CalyCore
import Foundation

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List calendar events"
    )

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
            if json {
                print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!)
            } else {
                print("Error: Access denied")
            }
            return
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let start = from.flatMap { df.date(from: $0) } ?? (includePast ? Calendar.current.startOfDay(for: Date()) : Date())
        let end = to.flatMap { df.date(from: $0) }.map { Calendar.current.date(byAdding: .day, value: 1, to: $0)! } ?? Calendar.current.date(byAdding: .day, value: days, to: start)!

        let filters = calendar?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        var events = await manager.getEvents(from: start, to: end, calendars: filters)
        if let limit = limit { events = Array(events.prefix(limit)) }

        if json {
            let result = ResultOutput(success: true, count: events.count, data: events, error: nil)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            print(String(data: try encoder.encode(result), encoding: .utf8)!)
        } else {
            for e in events {
                print("[\(e.calendarName)] \(e.title)\n  When: \(e.startDate)\n")
            }
        }
    }
}
