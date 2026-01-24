import ArgumentParser
import CalyCore
import Foundation

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a calendar event"
    )

    @Argument(help: "Event identifier to update")
    var eventId: String

    @Option(help: "New title")
    var title: String?

    @Option(help: "New start date (ISO8601)")
    var start: String?

    @Option(help: "New end date (ISO8601)")
    var end: String?

    @Option(help: "New location")
    var location: String?

    @Option(help: "New notes")
    var notes: String?

    func run() async throws {
        let manager = CalendarManager.shared
        if try await !manager.requestAccess() {
            print("Error: Calendar access denied")
            return
        }

        let iso = ISO8601DateFormatter()
        let startDate = start.flatMap { iso.date(from: $0) }
        let endDate = end.flatMap { iso.date(from: $0) }

        do {
            let updated = try await manager.updateEvent(
                eventIdentifier: eventId,
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: location,
                notes: notes
            )
            if updated {
                print("Updated: \(eventId)")
            } else {
                print("Error: Event not found")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
