//
//  PeriMeleonResponder.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP

/// Responds to all incoming
struct PeriMeleonResponder: HTTPServerResponder {
    private let memberProcessor = MemberProcessor()
    
    func respond(to req: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
        guard req.url.path.hasPrefix("/member") else {
            print("we don't do \(req.url.path)")
            let res = HTTPResponse(status: .notFound)
            return worker.eventLoop.newSucceededFuture(result: res)
        }
        guard let bodyData = req.body.data else {
            print("no data in body")
            let res = HTTPResponse(status: .notFound) //TODO need another status
            return worker.eventLoop.newSucceededFuture(result: res)
        }
        print("Received: \(req.body)")
        let response = memberProcessor.process(path: req.url.path,
                                               operand: String(data: bodyData, encoding: .utf8) ?? "")
        return worker.eventLoop.newSucceededFuture(result: response)
//        do {
//            let command = try JSONDecoder().decode(Command.self,
//                                                   from: String(data: bodyData, encoding: .utf8) ?? "")
//            let response = makeResponse(error: nil, response: "got it")
//            return worker.eventLoop.newSucceededFuture(result: response)
//        } catch {
//            let response = makeResponse(error: error, response: "not even JSON, dude")
//            return worker.eventLoop.newSucceededFuture(result: response)
//        }
    }
}

public func makeResponse(status: HTTPResponseStatus, error: Error?, response: String) -> HTTPResponse {
    let errorString = error?.localizedDescription ?? ""
    let responseObject = PeriMeleonResponse(error: errorString, response: response)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let responseBody = try! encoder.encode(responseObject)
    let response = HTTPResponse(status: status, body: responseBody)
    return response
}
