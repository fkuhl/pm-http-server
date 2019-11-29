import HTTP



public let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

public let jsonDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .formatted(dateFormatter)
    return d
}()

public let jsonEncoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .formatted(dateFormatter)
    e.outputFormatting = .prettyPrinted
    return e
}()


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
