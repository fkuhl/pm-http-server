//
//  EchoResponder.swift
//  
//
//  Created by Frederick Kuhl on 9/11/19.
//

import HTTP

/// Echoes the request as a response.
struct EchoResponder: HTTPServerResponder {
    /// See `HTTPServerResponder`.
    func respond(to req: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
        print("received path: \(req.url.path)")
        if req.url.path != "/api" {
            let res = HTTPResponse(status: .notFound)
            return worker.eventLoop.newSucceededFuture(result: res)
        }
        // Create an HTTPResponse with the same body as the HTTPRequest
        print("Received: \(req.body)")
        let res = HTTPResponse(body: req.body)
        // We don't need to do any async work here, we can just
        // se the Worker's event-loop to create a succeeded future.
        return worker.eventLoop.newSucceededFuture(result: res)
    }
}
