import ArgumentParser
import CalyCore
import Foundation

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a calendar event"
    )

    @Argument(help: "Event identifier to delete")
    var eventId: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var force: Bool = false

    func run() async throws {
        let manager = CalendarManager.shared
        if try await !manager.requestAccess() {
            print("Error: Calendar access denied")
            return
        }

        if !force {
            print("Are you sure you want to delete this event? (y/N)")
            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print("Cancelled")
                return
            }
        }

        do {
            let deleted = try await manager.deleteEvent(eventIdentifier: eventId)
            if deleted {
                print("Deleted: \(eventId)")
            } else {
                print("Error: Event not found with identifier '\(eventId)'")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
