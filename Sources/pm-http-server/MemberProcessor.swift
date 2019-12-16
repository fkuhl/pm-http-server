//
//  MemberProcessor.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP

class MemberProcessor {
    private let mongoProxyStore = ThreadSpecificVariable<MongoProxy>()
    
    func process(path: String, operand: String, on eventLoop: EventLoop) -> EventLoopFuture<HTTPResponse> {
        let mongoProxy = getCurrentMongoProxy(on: eventLoop)
        NSLog("dispatching \(path)")
        switch path {
        case "/member/create":
            return eventLoop.submit {
                return processCreate(path: path, mongoProxy: mongoProxy, operand: operand, type: MemberValue.self, on: eventLoop)
            }
        case "/member/read":
            return eventLoop.submit {
                return processRead(path: path, mongoProxy: mongoProxy, operand: operand, type: MemberValue.self, on: eventLoop)
            }
        case "/member/readAll":
            return eventLoop.submit {
                return processReadAll(path: path, mongoProxy: mongoProxy, operand: operand, type: Member.self, on: eventLoop)
            }
        case "/member/update":
            return eventLoop.submit {
                return processUpdate(path: path, mongoProxy: mongoProxy, operand: operand, type: Member.self, on: eventLoop)
            }
        case "/member/delete":
            return eventLoop.submit {
                return processDelete(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case "/member/drop":
            return eventLoop.submit {
                return processDrop(path: path, mongoProxy: mongoProxy, on: eventLoop)
            }
        default:
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "unrecognized op '\(path)'"))
        }
    }
    
    private func getCurrentMongoProxy(on eventLoop: EventLoop) -> MongoProxy {
        if let currentProxy = mongoProxyStore.currentValue {
            return currentProxy
        }
        let newProxy = MongoProxy(collectionName: .members)
        do {
            let count = try newProxy.count()
            NSLog("proxy found \(count) documents")
            mongoProxyStore.currentValue = newProxy
            return newProxy
        } catch {
            NSLog("proxy doesnt appear to be connected: \(error)")
            abort()
        }
    }

}

struct SingleID: Decodable {
    let id: String
}
