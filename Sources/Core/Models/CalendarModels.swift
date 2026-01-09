import Foundation
import EventKit

/// Output model for a calendar event
public struct CalendarEventOutput: Codable, Sendable {
    public let id: String
    public let title: String
    public let location: String?
    public let notes: String?
    public let startDate: String
    public let endDate: String
    public let calendarName: String
    public let calendarColor: String?
    public let isAllDay: Bool
    public let url: String?

    public init(
        id: String,
        title: String,
        location: String?,
        notes: String?,
        startDate: String,
        endDate: String,
        calendarName: String,
        calendarColor: String?,
        isAllDay: Bool,
        url: String?
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.calendarName = calendarName
        self.calendarColor = calendarColor
        self.isAllDay = isAllDay
        self.url = url
    }
}

/// Output model for a calendar
public struct CalendarOutput: Codable, Sendable {
    public let id: String
    public let title: String
    public let type: String
    public let color: String?
    public let source: String
    public let isSubscribed: Bool
    public let isImmutable: Bool

    public init(
        id: String,
        title: String,
        type: String,
        color: String?,
        source: String,
        isSubscribed: Bool,
        isImmutable: Bool
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.color = color
        self.source = source
        self.isSubscribed = isSubscribed
        self.isImmutable = isImmutable
    }
}

/// Generic result wrapper for JSON output
public struct ResultOutput<T: Codable & Sendable>: Codable, Sendable {
    public let success: Bool
    public let count: Int
    public let data: T
    public let error: String?

    public init(success: Bool, count: Int, data: T, error: String?) {
        self.success = success
        self.count = count
        self.data = data
        self.error = error
    }
}

// MARK: - EKEvent Extension

extension EKEvent {
    /// Converts an EKEvent to a CalendarEventOutput
    public func toOutput() -> CalendarEventOutput {
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

// MARK: - EKCalendar Extension

extension EKCalendar {
    /// Converts an EKCalendar to a CalendarOutput
    public func toOutput() -> CalendarOutput {
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

    /// Returns the calendar type as a string
    public var calendarTypeString: String {
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

// MARK: - Color Utilities

/// Converts a CGColor to a hex string
public func colorToHex(_ cgColor: CGColor) -> String {
    guard let components = cgColor.components, components.count >= 3 else {
        return "#000000"
    }
    let r = Int(components[0] * 255)
    let g = Int(components[1] * 255)
    let b = Int(components[2] * 255)
    return String(format: "#%02X%02X%02X", r, g, b)
}
