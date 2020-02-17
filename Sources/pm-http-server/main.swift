import HTTP


// Create an EventLoopGroup with an appropriate number
// of threads for the system we are running on.
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
// Make sure to shutdown the group when the application exits.
defer { try! group.syncShutdownGracefully() }

// Start an HTTPServer using our EchoResponder
// We are fine to use `wait()` here since we are on the main thread.
let server = try HTTPServer.start(
    hostname: "localhost",
    port: 8123,
    responder: PeriMeleonResponder(),
    on: group
).wait()
print("We're up with \(System.coreCount) cores...")

// Wait for the server to close (indefinitely).
try server.onClose.wait()
