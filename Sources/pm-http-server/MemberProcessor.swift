//
//  MemberProcessor.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP

class MemberProcessor {
    private let memberStore = MemberStore.sharedInstance
    private let mongoProxyStore = ThreadSpecificVariable<MongoProxy>()
    
    func process(path: String, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        let mongoProxy = getCurrentMongoProxy(on: eventLoop)
        if path == "/member/create" {
            do {
                let memberValue = try JSONDecoder().decode(Member.Value.self,
                                                           from: operand)
                let identified = try mongoProxy.add(memberValue: memberValue)
                return makeResponse(status: .ok, response: identified)
            } catch let error as DecodingError  {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            } catch {
                return makeErrorResponse(status: .internalServerError, error: error, response: path + ": add failed")
            }
        } else if path == "/member/read" {
            do {
                let idToRead = try JSONDecoder().decode(SingleID.self,
                                                        from: operand)
                if let member = memberStore.read(id: idToRead.id) {
                    return makeResponse(status: .ok, response: member)
                } else {
                    return makeResponse(status: .notFound, response: "id \(idToRead.id) not found")
                }
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            }
        } else if path == "/member/readAll" {
            let members = memberStore.readAll()
            return makeResponse(status: .ok, response: members)
        } else if path == "/member/update" {
            do {
                let member = try JSONDecoder().decode(Member.self, from: operand)
                if let updated = memberStore.update(member: member) {
                    return makeResponse(status: .ok, response: updated)
                } else {
                    return makeErrorResponse(status: .notFound, error: nil, response: path + ": id \(member.id) not found")
                }
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            }
        } else if path == "/member/delete" {
            do {
                let idToDelete = try JSONDecoder().decode(SingleID.self, from: operand)
                if let deleted = memberStore.delete(id: idToDelete.id) {
                    return makeResponse(status: .ok, response: deleted)
                } else {
                    return makeResponse(status: .notFound, response: "id \(idToDelete.id) not found")
                }
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            }
        } else {
            return makeErrorResponse(status: .badRequest, error: nil, response: "unrecognized op '\(path)'")
        }
    }
    
    private func getCurrentMongoProxy(on eventLoop: EventLoop) -> MongoProxy {
        if let currentProxy = mongoProxyStore.currentValue {
            return currentProxy
        }
        let newProxy = MongoProxy(on: eventLoop)
        mongoProxyStore.currentValue = newProxy
        return newProxy
    }
}

struct SingleID: Decodable {
    let id: Int
}
