import CalyCore
import Foundation
import Logging
import MCP

/// Caly MCP Server - Native Swift implementation
/// Replaces the TypeScript/Bun MCP server for better performance
public actor CalyMCPServer {
    private let logger: Logger
    private let toolHandler: CalyToolHandler

    public init() {
        var logger = Logger(label: "caly.mcp")
        logger.logLevel = .info
        self.logger = logger
        self.toolHandler = CalyToolHandler(logger: logger)
    }

    public func run() async throws {
        logger.info("Starting Caly MCP Server v1.0.0")

        let server = Server(
            name: "caly",
            version: "1.0.0",
            capabilities: .init(
                tools: .init()
            )
        )

        // Register tool handlers
        await server.withMethodHandler(ListTools.self) { [toolHandler] _ in
            await toolHandler.listTools()
        }

        await server.withMethodHandler(CallTool.self) { [toolHandler] params in
            try await toolHandler.callTool(params)
        }

        logger.info("Tools registered: caly_list, caly_search, caly_calendars, caly_create")

        // Start server with stdio transport
        let transport = StdioTransport(logger: logger)
        try await server.start(transport: transport)

        logger.info("MCP Server started, waiting for connections...")
        await server.waitUntilCompleted()
    }
}
