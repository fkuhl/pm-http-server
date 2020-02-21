//
//  PeriMeleonResponder.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP
import PMDataTypes

/// Responds to all incoming
struct PeriMeleonResponder: HTTPServerResponder {
    private let dataOperationsProcessor = DataOperationsProcessor()
    
    func respond(to req: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
        let bodyText: String
        if let bodyData = req.body.data {
            bodyText = String(data: bodyData, encoding: .utf8) ?? ""
        } else {
            bodyText = ""
        }
        print("Received: '\(req.body)'")
        let response = dataOperationsProcessor.process(url: req.url,
                                               operand: bodyText,
                                               on: worker.eventLoop)
        return response
    }
}


public func makeErrorResponse(status: HTTPResponseStatus, error: Error?, response: String) -> HTTPResponse {
    let errorString = error?.localizedDescription ?? ""
    let responseObject = ErrorResponse(error: errorString, response: response)
    let responseBody = try! jsonEncoder.encode(responseObject)
    let response = HTTPResponse(status: status, body: responseBody)
    return response
}

public func makeResponse<R: Encodable>(status: HTTPResponseStatus, response: R) -> HTTPResponse {
    let responseBody = try! jsonEncoder.encode(response)
    let response = HTTPResponse(status: status, body: responseBody)
    return response
}
