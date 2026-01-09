import ArgumentParser
import CalyCore
import Foundation

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search calendar events"
    )

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

        if json {
            let result = ResultOutput(success: true, count: events.count, data: events, error: nil)
            print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!)
        } else {
            for e in events {
                print("[\(e.calendarName)] \(e.title)")
            }
        }
    }
}
