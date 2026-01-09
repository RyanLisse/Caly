import ArgumentParser
import CalyCore
import Foundation

@main
struct CalyCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "caly",
        abstract: "🧙 Caly: Your quirky calendar wizard CLI",
        subcommands: [ListCommand.self, SearchCommand.self, CalendarsCommand.self, CreateCommand.self],
        defaultSubcommand: ListCommand.self
    )
}
