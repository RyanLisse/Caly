import ArgumentParser
import CalyCore
import Foundation

struct CreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create event"
    )

    @Argument var title: String
    @Option var start: String
    @Option var end: String
    @Option var calendar: String?
    @Flag var allDay: Bool = false

    func run() async throws {
        let manager = CalendarManager.shared
        if try await !manager.requestAccess() { return }

        let iso = ISO8601DateFormatter()
        guard let s = iso.date(from: start), let e = iso.date(from: end) else {
            print("Error: Invalid date format. Use ISO8601 format (e.g., 2026-01-04T10:00:00Z)")
            return
        }

        let id = try await manager.createEvent(
            title: title,
            startDate: s,
            endDate: e,
            location: nil,
            notes: nil,
            isAllDay: allDay,
            calendarName: calendar
        )
        print("Created: \(id)")
    }
}
