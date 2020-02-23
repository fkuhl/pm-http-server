import HTTP
import Logging
import Foundation

LoggingSystem.bootstrap {
    label in
    return StreamLogHandler.standardOutput(label: label)
}
var logger = Logger(label: "com.tamelea.pm.http_server")
var logLevels = [
    "trace":    Logger.Level.trace,
    "debug":    Logger.Level.debug,
    "info":     Logger.Level.info,
    "notice":   Logger.Level.notice,
    "warning":  Logger.Level.warning,
    "error":    Logger.Level.error,
    "critical": Logger.Level.critical
]
logger.logLevel = .debug
if let logLevel = ProcessInfo.processInfo.environment["PM_LOG_LEVEL"] {
    if let logLevel = logLevels[logLevel] {
        logger.logLevel = logLevel
        logger.info("Log level is \(logLevel)")
    }
}


// Create an EventLoopGroup with an appropriate number
// of threads for the system we are running on.
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
// Make sure to shutdown the group when the application exits.
defer { try! group.syncShutdownGracefully() }

// Start an HTTPServer using our EchoResponder
// We are fine to use `wait()` here since we are on the main thread.
let server = try HTTPServer.start(
    hostname: "0.0.0.0",
    port: 8123,
    responder: PeriMeleonResponder(),
    on: group
).wait()
logger.info("We're up with \(System.coreCount) cores...")
logger.info("host '\(Host.current().localizedName ?? "")'")
for interface in try! System.enumerateInterfaces() {
    logger.info("NIO interface name '\(interface.name)' addr '\(interface.address)'")
}

// Wait for the server to close (indefinitely).
try server.onClose.wait()
