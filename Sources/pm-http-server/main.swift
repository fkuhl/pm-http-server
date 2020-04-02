import Foundation
import NIO
import Logging

LoggingSystem.bootstrap {
    label in
    return StreamLogHandler.standardOutput(label: label)
}
var logger = Logger(label: "com.tamelea.pm.http_server")
logger.logLevel = .debug
if let logLevelEnv = ProcessInfo.processInfo.environment["PM_LOG_LEVEL"],
    let logLevel = Logger.Level(rawValue: logLevelEnv) {
    logger.logLevel = logLevel
    logger.info("Log level set from environment: \(logLevel)")
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
