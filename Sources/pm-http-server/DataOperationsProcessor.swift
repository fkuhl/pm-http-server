//
//  DataOperationsProcessor.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import HTTP
import Logging
import PMDataTypes

class DataOperationsProcessor {
    
    func process(url: URL, operand: String, on eventLoop: EventLoop) -> EventLoopFuture<HTTPResponse> {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "URL invalid: '\(url)'"))
        }
        let path = urlComponents.path
        let pathComponents = path.split(separator: "/")
        guard pathComponents.count == 2 else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "op path invalid: '\(path)'"))
        }
        guard let opCategory = OpCategory(rawValue: String(pathComponents[0])) else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "invalid op category: '\(pathComponents[0])'"))
        }
        guard let operation = CrudOperation(rawValue: String(pathComponents[1])) else {
            return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "invalid op: '\(pathComponents[1])'"))
        }

        logger.info("dispatching \(path)")
        return eventLoop.submit {
            do {
                switch opCategory {
                case .members:
                    switch operation {
                    case .create:
                        return makeErrorResponse(status: .badRequest, error: nil, response: "cannot create separate Member")
                    case .read:
                        //TODO
                        return try LocalCache.sharedInstance.readMember(id: "figure out how to extract id")
                    case .readAll:
                        return try LocalCache.sharedInstance.readAllMembers()
                    case .update:
                        let member = try jsonDecoder.decode(Member.self, from: operand)
                        return LocalCache.sharedInstance.update(member: member, on: eventLoop)
                    case .drop:
                        return makeErrorResponse(status: .badRequest, error: nil, response: "cannot drop Member")
                    }
                case .households:
                    switch operation {
                    case .create:
                        let data = try jsonDecoder.decode(NewFamilyData.self, from: operand)
                        return LocalCache.sharedInstance.createHousehold(data: data, on: eventLoop)
                    case .read:
                        //TODO
                        return LocalCache.sharedInstance.readHousehold(id: "figure out how to extract id")
                    case .readAll:
                        return LocalCache.sharedInstance.readAllHouseholds()
                    case .update:
                        let household = try jsonDecoder.decode(HouseholdDocument.self, from: operand)
                        return LocalCache.sharedInstance.update(household: household, on: eventLoop)
                    case .drop:
                        return LocalCache.sharedInstance.drop()
                    }
                case .transaction:
                    return makeErrorResponse(status: .badRequest, error: nil, response: "coming soon")
                }
            } catch {
                return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
            }
        }
    }
        
//
//        switch operation {
//        case .create:
//            return eventLoop.submit {
//                do {
//                    /** Why switch on the collection type? DataType and ValueType are protocols-with-associated-type, so they can
//                     only function as generic constraints. Not the best advertisement for the Swift type system! */
//                    switch collection {
//                    case .members:
//                        let value = try jsonDecoder.decode(MemberValue.self, from: operand)
//                        return processCreate(path: path, mongoProxy: mongoProxy, operand: value, on: eventLoop)
//                    case .households:
//                        let value = try jsonDecoder.decode(HouseholdValue.self, from: operand)
//                        return processCreate(path: path, mongoProxy: mongoProxy, operand: value, on: eventLoop)
//                    case .addresses:
//                        let value = try jsonDecoder.decode(AddressValue.self, from: operand)
//                        return processCreate(path: path, mongoProxy: mongoProxy, operand: value, on: eventLoop)
//                    }
//                } catch {
//                    return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
//                }
//            }
//        case .read:
//            guard let queryItems = urlComponents.queryItems, let first = queryItems.first, let id = first.value else {
//                return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "no query item for id"))
//            }
//            logger.info("ops proc read id \(id)")
//            return eventLoop.submit {
//                switch collection {
//                case .members:
//                    return processRead(path: path, mongoProxy: mongoProxy, idToRead: id, type: MemberValue.self, on: eventLoop)
//                case .households:
//                    return processRead(path: path, mongoProxy: mongoProxy, idToRead: id, type: HouseholdValue.self, on: eventLoop)
//                case .addresses:
//                    return processRead(path: path, mongoProxy: mongoProxy, idToRead: id, type: AddressValue.self, on: eventLoop)
//                }
//            }
//        case .readAll:
//            return eventLoop.submit {
//                switch collection {
//                case .members:
//                    return processReadAll(path: path, mongoProxy: mongoProxy, type: Member.self, on: eventLoop)
//                case .households:
//                    return processReadAll(path: path, mongoProxy: mongoProxy, type: Household.self, on: eventLoop)
//                case .addresses:
//                    return processReadAll(path: path, mongoProxy: mongoProxy, type: Address.self, on: eventLoop)
//                }
//            }
//        case .update:
//            return eventLoop.submit {
//                do {
//                    switch collection {
//                    case .members:
//                        let member = try jsonDecoder.decode(Member.self, from: operand)
//                        return processUpdate(path: path, mongoProxy: mongoProxy, operand: member, type: Member.self, on: eventLoop)
//                    case .households:
//                        let household = try jsonDecoder.decode(Household.self, from: operand)
//                        return processUpdate(path: path, mongoProxy: mongoProxy, operand: household, type: Household.self, on: eventLoop)
//                    case .addresses:
//                        let address = try jsonDecoder.decode(Address.self, from: operand)
//                        return processUpdate(path: path, mongoProxy: mongoProxy, operand: address, type: Address.self, on: eventLoop)
//                    }
//                } catch {
//                    return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
//                }
//             }
//        case .delete:
//            guard let queryItems = urlComponents.queryItems, let first = queryItems.first, let id = first.value else {
//                return eventLoop.newSucceededFuture(result: makeErrorResponse(status: .badRequest, error: nil, response: "no query item for id"))
//            }
//            logger.info("ops proc read id \(id)")
//            return eventLoop.submit {
//                return processDelete(path: path, mongoProxy: mongoProxy, idToDelete: id, on: eventLoop)
//            }
//        case .drop:
//            return eventLoop.submit {
//                return processDrop(path: path, mongoProxy: mongoProxy, on: eventLoop)
//            }
//        }
//    }

}

struct SingleID: Decodable {
    let id: String
}
