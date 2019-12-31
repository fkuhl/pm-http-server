//
//  MemberProcessor.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP
import PMDataTypes

class DataOperationsProcessor {
    private var mongoProxyStore = [CollectionName : ThreadSpecificVariable<MongoProxy>]()
    
    func process(path: String, operand: String, on eventLoop: EventLoop) -> EventLoopFuture<HTTPResponse> {
        let pathComponents = path.split(separator: "/")
        guard pathComponents.count == 2 else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "op path invalid: '\(path)'"))
        }
        guard let collection = CollectionName(rawValue: String(pathComponents[0])) else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "invalid collection: '\(pathComponents[0])'"))
        }
        guard let operation = CrudOperation(rawValue: String(pathComponents[1])) else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "invalid op: '\(pathComponents[1])'"))
        }
        
        let mongoProxy = getCurrentMongoProxy(for: collection, on: eventLoop)
        NSLog("dispatching \(path)")
        switch operation {
        case .create:
            return eventLoop.submit {
                do {
                    /** Why switch on the collection type? DataType and ValueType are protocols-with-associated-type, so they can
                     only function as generic constraints. Not the best advertisement for the Swift type system! */
                    switch collection {
                    case .members:
                        let value = try jsonDecoder.decode(MemberValue.self, from: operand)
                        return processCreate(path: path, mongoProxy: mongoProxy, operand: value, on: eventLoop)
                    case .households:
                        let value = try jsonDecoder.decode(HouseholdValue.self, from: operand)
                        return processCreate(path: path, mongoProxy: mongoProxy, operand: value, on: eventLoop)
                    case .addresses:
                        let value = try jsonDecoder.decode(AddressValue.self, from: operand)
                        return processCreate(path: path, mongoProxy: mongoProxy, operand: value, on: eventLoop)
                    }
                } catch {
                    return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
                }
            }
        case .read:
            return eventLoop.submit {
                switch collection {
                case .members:
                    return processRead(path: path, mongoProxy: mongoProxy, operand: operand, type: MemberValue.self, on: eventLoop)
                case .households:
                    return processRead(path: path, mongoProxy: mongoProxy, operand: operand, type: HouseholdValue.self, on: eventLoop)
                case .addresses:
                    return processRead(path: path, mongoProxy: mongoProxy, operand: operand, type: AddressValue.self, on: eventLoop)
                }
            }
        case .readAll:
            return eventLoop.submit {
                switch collection {
                case .members:
                    return processReadAll(path: path, mongoProxy: mongoProxy, operand: operand, type: Member.self, on: eventLoop)
                case .households:
                    return processReadAll(path: path, mongoProxy: mongoProxy, operand: operand, type: Household.self, on: eventLoop)
                case .addresses:
                    return processReadAll(path: path, mongoProxy: mongoProxy, operand: operand, type: Address.self, on: eventLoop)
                }
            }
        case .update:
            return eventLoop.submit {
                do {
                    switch collection {
                    case .members:
                        let member = try jsonDecoder.decode(Member.self, from: operand)
                        return processUpdate(path: path, mongoProxy: mongoProxy, operand: member, type: Member.self, on: eventLoop)
                    case .households:
                        let household = try jsonDecoder.decode(Household.self, from: operand)
                        return processUpdate(path: path, mongoProxy: mongoProxy, operand: household, type: Household.self, on: eventLoop)
                    case .addresses:
                        let address = try jsonDecoder.decode(Address.self, from: operand)
                        return processUpdate(path: path, mongoProxy: mongoProxy, operand: address, type: Address.self, on: eventLoop)
                    }
                } catch {
                    return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
                }
             }
        case .delete:
            return eventLoop.submit {
                return processDelete(path: path, mongoProxy: mongoProxy, operand: operand, on: eventLoop)
            }
        case .drop:
            return eventLoop.submit {
                return processDrop(path: path, mongoProxy: mongoProxy, on: eventLoop)
            }
        }
    }
    
    private func getCurrentMongoProxy(for collection: CollectionName, on eventLoop: EventLoop) -> MongoProxy {
        if let threadSpecificVariable = mongoProxyStore[collection], let currentProxy = threadSpecificVariable.currentValue {
            return currentProxy
        }
        let newProxy = MongoProxy(collectionName: collection)
        do {
            let count = try newProxy.count()
            NSLog("proxy found \(count) documents")
            var threadSpecificVariable = mongoProxyStore[collection]
            if threadSpecificVariable == nil { threadSpecificVariable = ThreadSpecificVariable<MongoProxy>() }
            threadSpecificVariable!.currentValue = newProxy
            mongoProxyStore[collection] = threadSpecificVariable
            return newProxy
        } catch {
            NSLog("proxy doesn't appear to be connected: \(error)")
            abort()
        }
    }

}

struct SingleID: Decodable {
    let id: String
}
