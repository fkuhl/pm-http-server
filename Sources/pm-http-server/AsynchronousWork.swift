//
//  AsynchronousWork.swift
//  Async
//
//  Created by Frederick Kuhl on 11/29/19.
//

import HTTP
import Logging
import PMDataTypes


//func processCreate<V: ValueType>(path: String,
//                                 mongoProxy: MongoProxy,
//                                 operand: V,
//                                 on eventLoop: EventLoop) -> HTTPResponse {
//    do {
//        let identified = try mongoProxy.add(dataValue: operand)
//        return makeResponse(status: .ok, response: identified)
//    } catch {
//        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": add failed")
//    }
//}
//
//func processRead<V: ValueType>(path: String,
//                               mongoProxy: MongoProxy,
//                               idToRead: Id,
//                               type: V.Type,
//                               on eventLoop: EventLoop) -> HTTPResponse {
//    do {
//        if let value: V = try mongoProxy.read(id: idToRead) {
//            return makeResponse(status: .ok, response: value)
//        } else {
//            return makeResponse(status: .notFound, response: "id \(idToRead) not found")
//        }
//    } catch {
//        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": read failed")
//    }
//}
//
//func processReadAll<D: DataType>(path: String,
//                                 mongoProxy: MongoProxy,
//                                 type: D.Type,
//                                 on eventLoop: EventLoop) -> HTTPResponse {
//    do {
//        let matchingDocuments: [D] = try mongoProxy.readAll()
//        return makeResponse(status: .ok, response: matchingDocuments)
//    } catch {
//        logger.error("readAll failed: \(error.localizedDescription)")
//        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": readAll failed")
//    }
//}
//
//func processUpdate<D: DataType>(path: String,
//                                mongoProxy: MongoProxy,
//                                operand: D,
//                                type: D.Type,
//                                on eventLoop: EventLoop) -> HTTPResponse {
//    do {
//        if try mongoProxy.replace(document: operand) {
//            return makeResponse(status: .ok, response: operand)
//        } else {
//            return makeErrorResponse(status: .notFound, error: nil, response: path + ": id \(operand.id) not found")
//        }
//    } catch {
//        return makeErrorResponse(status: .badRequest, error: error, response: path + ": update failed")
//    }
//}
//
//func processDelete(path: String,
//                   mongoProxy: MongoProxy,
//                   idToDelete: Id,
//                   on eventLoop: EventLoop) -> HTTPResponse {
//    do {
//        if try mongoProxy.delete(id: idToDelete) {
//            return makeResponse(status: .ok, response: "deleted id \(idToDelete)")
//        } else {
//            return makeResponse(status: .notFound, response: "id \(idToDelete) not found")
//        }
//    } catch let error as DecodingError  {
//        return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
//    } catch {
//        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": delete failed")
//    }
//}
//
//func processDrop(path: String,
//                 mongoProxy: MongoProxy,
//                 on eventLoop: EventLoop) -> HTTPResponse {
//    do {
//        try mongoProxy.drop()
//        return makeResponse(status: .ok, response: "dropped")
//    } catch {
//        return makeErrorResponse(status: .badRequest, error: error, response: path)
//    }
//}
