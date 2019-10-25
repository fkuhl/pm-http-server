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
        switch path {
        case "/member/create":
            return processCreate(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
        case "/member/read":
            return processRead(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
        case "/member/readAll":
            return processReadAll(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
        case "/member/update":
            return processUpdate(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
        case "/member/delete":
            return processDelete(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
        default:
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
    
    private func processCreate(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
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
    }
    
    private func processRead(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            let idToRead = try JSONDecoder().decode(SingleID.self,
                                                    from: operand)
            if let member = try mongoProxy.read(id: idToRead.id) {
                return makeResponse(status: .ok, response: member)
            } else {
                return makeResponse(status: .notFound, response: "id \(idToRead.id) not found")
            }
        } catch {
            return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
        }
    }
    
    private func processReadAll(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            let members = try mongoProxy.readAll()
            return makeResponse(status: .ok, response: members)
        } catch {
            return makeErrorResponse(status: .internalServerError, error: error, response: path + ": readAll failed")
        }
    }
    
    private func processUpdate(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
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
    }
    
    private func processDelete(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
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
    }

}

struct SingleID: Decodable {
    let id: String
}
