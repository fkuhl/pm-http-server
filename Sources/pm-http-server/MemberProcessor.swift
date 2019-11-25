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
        switch path {
        case "/member/create":
            return eventLoop.submit {
                return self.processCreate(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case "/member/read":
            return eventLoop.submit {
                return self.processRead(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case "/member/readAll":
            return eventLoop.submit {
                return self.processReadAll(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case "/member/update":
            return eventLoop.submit {
                return self.processUpdate(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case "/member/delete":
            return eventLoop.submit {
                return self.processDelete(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case "/member/drop":
            return eventLoop.submit {
                return self.processDrop(path: path, mongoProxy: mongoProxy, on: eventLoop)
            }
        default:
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "unrecognized op '\(path)'"))
        }
    }
    
    private func getCurrentMongoProxy(on eventLoop: EventLoop) -> MongoProxy {
        if let currentProxy = mongoProxyStore.currentValue {
            return currentProxy
        }
        let newProxy = MongoProxy(collectionName: "Members")
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
    
    //MARK: Asynchronous work units
    
    private func processCreate(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            let memberValue = try jsonDecoder.decode(Member.self, from: operand)
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
            let idToRead = try jsonDecoder.decode(SingleID.self,
                                                    from: operand)
            if let member = try mongoProxy.read(id: idToRead._id) {
                return makeResponse(status: .ok, response: member)
            } else {
                return makeResponse(status: .notFound, response: "id \(idToRead._id) not found")
            }
        } catch let error as DecodingError {
            return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
        } catch {
            return makeErrorResponse(status: .badRequest, error: error, response: path + ": some other error: \(error)")
        }
    }
    
    private func processReadAll(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            let members = try mongoProxy.readAll()
            return makeResponse(status: .ok, response: members)
        } catch {
            return makeErrorResponse(status: .internalServerError, error: error, response: path + ": readAll failed: \(error)")
        }
    }
    
    private func processUpdate(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            let member = try jsonDecoder.decode(Member.self, from: operand)
            if try mongoProxy.replace(member: member) {
                return makeResponse(status: .ok, response: member)
            } else {
                return makeErrorResponse(status: .notFound,
                                         error: nil,
                                         response: path + ": id \(member._id ?? "nil id") not found")
            }
            } catch let error as DecodingError {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": some other error: \(error)")
            }
    }
    
    private func processDelete(path: String, mongoProxy: MongoProxy, operand: String, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            let idToDelete = try jsonDecoder.decode(SingleID.self, from: operand)
            if try mongoProxy.delete(id: idToDelete._id) {
                return makeResponse(status: .ok, response: "deleted id \(idToDelete._id)")
            } else {
                return makeResponse(status: .notFound, response: "id \(idToDelete._id) not found")
            }
            } catch let error as DecodingError {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": some other error: \(error)")
            }
    }

    private func processDrop(path: String, mongoProxy: MongoProxy, on eventLoop: EventLoop) -> HTTPResponse {
        do {
            try mongoProxy.drop()
            return makeResponse(status: .ok, response: "dropped")
        } catch {
            return makeErrorResponse(status: .badRequest, error: error, response: path)
        }
    }

}

struct SingleID: Decodable {
    let _id: String
}
