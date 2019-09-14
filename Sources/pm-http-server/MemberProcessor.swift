//
//  MemberProcessor.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP

class MemberProcessor {
    private let memberStore = MemberStore.sharedInstance
    
    func process(path: String, operand: String) -> HTTPResponse {
        if path == "/member/create" {
            do {
                let memberValue = try JSONDecoder().decode(Member.Value.self,
                from: operand)
                let identified = memberStore.add(memberValue: memberValue)
                let response = MemberCreateResponse(error: "", member: identified)
                return makeResponse(status: .ok, response: response)
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            }
        } else {
            return makeErrorResponse(status: .badRequest, error: nil, response: "unrecognized op '\(path)'")
        }
    }
}

struct MemberCreateResponse: Encodable {
    let error: String
    let member: Member
}
