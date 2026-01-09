import ArgumentParser
import CalyCore
import Foundation

struct CalendarsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "List calendars"
    )

    @Flag var json: Bool = false

    func run() async throws {
        let manager = CalendarManager.shared
        if try await !manager.requestAccess() { return }

        let cals = await manager.getAllCalendars()
        if json {
            let result = ResultOutput(success: true, count: cals.count, data: cals, error: nil)
            print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!)
        } else {
            for c in cals {
                print("- \(c.title) [\(c.type)]")
            }
        }
    }
}
