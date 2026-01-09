import ArgumentParser
import CalyCore
import EventKit
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
    @Flag var debug: Bool = false

    func run() async throws {
        let manager = CalendarManager.shared

        if debug {
            let status = EKEventStore.authorizationStatus(for: .event)
            print("[DEBUG] Initial auth status: \(status.rawValue) (\(statusName(status)))")
        }

        let granted = try await manager.requestAccess()

        if debug {
            let status = EKEventStore.authorizationStatus(for: .event)
            print("[DEBUG] After request status: \(status.rawValue) (\(statusName(status)))")
            print("[DEBUG] Request returned: \(granted)")
        }
        if !granted {
            let status = EKEventStore.authorizationStatus(for: .event)
            var isWriteOnly = false
            if #available(macOS 14.0, *) {
                isWriteOnly = (status == .writeOnly)
            }

            let errorMsg: String
            if isWriteOnly {
                errorMsg = """
                Error: Write-only access granted 🚫

                Caly needs FULL calendar access to read events.
                1. Open System Settings > Privacy & Security > Calendars
                2. Find 'Caly' and enable "Full Access" (not just basic access)

                Or reset and re-grant: tccutil reset Calendar com.ryanlisse.caly
                Then run: open -a Caly
                """
            } else {
                errorMsg = """
                Error: Access denied 🚫

                Please enable calendar access in System Settings:
                1. Open System Settings
                2. Go to Privacy & Security > Calendars
                3. Enable FULL access for 'Caly'

                If 'Caly' is not listed, run: open -a Caly
                Then grant Full Access when prompted.
                """
            }
            
            let result = ResultOutput(success: false, count: 0, data: [CalendarEventOutput](), error: errorMsg)
            if json {
                print(String(data: try JSONEncoder().encode(result), encoding: .utf8)!)
            } else {
                print(errorMsg)
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

    private func statusName(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .fullAccess: return "fullAccess"
        case .writeOnly: return "writeOnly"
        @unknown default: return "unknown"
        }
    }
}
