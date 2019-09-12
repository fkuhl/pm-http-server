//
//  MemberProcessor.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP

class MemberProcessor {
    
    func process(path: String, operand: String) -> HTTPResponse {
        if path == "/member/create" {
            do {
                let member = try JSONDecoder().decode(Member.Public.self,
                from: operand)
                return makeResponse(status: .ok, error: nil, response: "got it")
            } catch {
                return makeResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            }
        } else {
            return makeResponse(status: .badRequest, error: nil, response: "unrecognized op '\(path)'")
        }
    }
}
