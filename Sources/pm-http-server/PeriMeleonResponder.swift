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
                                               operand: String(data: bodyData, encoding: .utf8) ?? "",
                                               on: worker.eventLoop)
        return response
    }
}

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


public func makeErrorResponse(status: HTTPResponseStatus, error: Error?, response: String) -> HTTPResponse {
    let errorString = error?.localizedDescription ?? ""
    let responseObject = ErrorResponse(error: errorString, response: response)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let responseBody = try! encoder.encode(responseObject)
    let response = HTTPResponse(status: status, body: responseBody)
    return response
}

public func makeResponse<R: Encodable>(status: HTTPResponseStatus, response: R) -> HTTPResponse {
    let responseBody = try! jsonEncoder.encode(response)
    let response = HTTPResponse(status: status, body: responseBody)
    return response
}
