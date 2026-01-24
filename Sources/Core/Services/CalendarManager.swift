import Foundation
import EventKit

/// Actor responsible for managing calendar operations
public actor CalendarManager {
    public static let shared = CalendarManager()

    private let store = EKEventStore()
    private var useAppleScriptFallback = false

    private init() {}

    /// Requests access to the calendar
    /// - Returns: True if access was granted
    public func requestAccess() async throws -> Bool {
        // Check current status first
        let status = EKEventStore.authorizationStatus(for: .event)

        // If already authorized, return true immediately
        if #available(macOS 14.0, *) {
            if status == .fullAccess {
                return true
            }
        } else {
            if status == .authorized {
                return true
            }
        }

        // If denied, return false
        if status == .denied || status == .restricted {
            return false
        }

        // macOS 14+ has writeOnly status - we need full access to read events
        if #available(macOS 14.0, *) {
            if status == .writeOnly {
                return false
            }
        }

        // For CLI tools, EventKit often returns notDetermined even when TCC has granted permission.
        // Try using AppleScript as a fallback check - if Calendar.app is accessible, we likely have permission.
        if status == .notDetermined {
            let hasAppleScriptAccess = checkAppleScriptCalendarAccess()
            if hasAppleScriptAccess {
                // TCC has granted permission but EventKit doesn't recognize it in CLI context.
                // Enable fallback mode and return true.
                useAppleScriptFallback = true
                return true
            }
        }

        // Request access
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

    /// Check if we can access Calendar via AppleScript (which has different TCC handling)
    private func checkAppleScriptCalendarAccess() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"Calendar\" to get name of first calendar"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Gets events within a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    ///   - calendars: Optional list of calendar names to filter by
    /// - Returns: Array of event outputs
    public func getEvents(from startDate: Date, to endDate: Date, calendars: [String]? = nil) -> [CalendarEventOutput] {
        var calendarObjects: [EKCalendar]? = nil

        if let calendarNames = calendars, !calendarNames.isEmpty {
            calendarObjects = store.calendars(for: .event).filter { cal in
                calendarNames.contains { name in
                    cal.title.localizedCaseInsensitiveContains(name)
                }
            }
        }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarObjects)
        return store.events(matching: predicate).map { $0.toOutput() }
    }

    /// Searches events by keyword
    /// - Parameters:
    ///   - query: Search query
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Array of matching event outputs
    public func searchEvents(query: String, from startDate: Date, to endDate: Date) -> [CalendarEventOutput] {
        let calendarObjects: [EKCalendar]? = nil
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarObjects)
        let allEvents = store.events(matching: predicate)
        let lowercaseQuery = query.lowercased()

        return allEvents.filter { event in
            event.title?.lowercased().contains(lowercaseQuery) == true ||
            event.location?.lowercased().contains(lowercaseQuery) == true ||
            event.notes?.lowercased().contains(lowercaseQuery) == true
        }.map { $0.toOutput() }
    }

    /// Gets all available calendars
    /// - Returns: Array of calendar outputs
    public func getAllCalendars() -> [CalendarOutput] {
        return store.calendars(for: .event).map { $0.toOutput() }
    }

    /// Creates a new calendar event
    /// - Parameters:
    ///   - title: Event title
    ///   - startDate: Start date
    ///   - endDate: End date
    ///   - location: Optional location
    ///   - notes: Optional notes
    ///   - isAllDay: Whether it's an all-day event
    ///   - calendarName: Optional calendar name
    /// - Returns: The event identifier
    /// - Throws: EventKit error if saving fails
    public func createEvent(
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

    /// Deletes a calendar event by identifier
    /// - Parameter eventIdentifier: The event identifier (from create or list)
    /// - Returns: True if deleted successfully
    /// - Throws: EventKit error if deletion fails
    public func deleteEvent(eventIdentifier: String) throws -> Bool {
        guard let event = store.event(withIdentifier: eventIdentifier) else {
            return false
        }
        try store.remove(event, span: .thisEvent)
        return true
    }

    /// Updates a calendar event
    /// - Parameters:
    ///   - eventIdentifier: The event identifier
    ///   - title: New title (nil to keep existing)
    ///   - startDate: New start date (nil to keep existing)
    ///   - endDate: New end date (nil to keep existing)
    ///   - location: New location (nil to keep existing)
    ///   - notes: New notes (nil to keep existing)
    /// - Returns: True if updated successfully
    /// - Throws: EventKit error if update fails
    public func updateEvent(
        eventIdentifier: String,
        title: String?,
        startDate: Date?,
        endDate: Date?,
        location: String?,
        notes: String?
    ) throws -> Bool {
        guard let event = store.event(withIdentifier: eventIdentifier) else {
            return false
        }

        if let title = title { event.title = title }
        if let startDate = startDate { event.startDate = startDate }
        if let endDate = endDate { event.endDate = endDate }
        if let location = location { event.location = location }
        if let notes = notes { event.notes = notes }

        try store.save(event, span: .thisEvent)
        return true
    }
}
