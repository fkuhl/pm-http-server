//
//  AsynchronousWork.swift
//  Async
//
//  Created by Frederick Kuhl on 11/29/19.
//

import HTTP
import PMDataTypes


func processCreate<V: ValueType>(path: String,
                                 mongoProxy: MongoProxy,
                                 operand: V,
                                 on eventLoop: EventLoop) -> HTTPResponse {
    do {
        let identified = try mongoProxy.add(dataValue: operand)
        return makeResponse(status: .ok, response: identified)
    } catch {
        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": add failed")
    }
}

func processRead<V: ValueType>(path: String,
                               mongoProxy: MongoProxy,
                               operand: String,
                               type: V.Type,
                               on eventLoop: EventLoop) -> HTTPResponse {
    do {
        let idToRead = try jsonDecoder.decode(SingleID.self,
                                              from: operand)
        if let value: V = try mongoProxy.read(id: idToRead.id) {
            return makeResponse(status: .ok, response: value)
        } else {
            return makeResponse(status: .notFound, response: "id \(idToRead.id) not found")
        }
    } catch let error as DecodingError  {
        return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
    } catch {
        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": read failed")
    }
}

func processReadAll<D: DataType>(path: String,
                                 mongoProxy: MongoProxy,
                                 operand: String,
                                 type: D.Type,
                                 on eventLoop: EventLoop) -> HTTPResponse {
    do {
        let matchingDocuments: [D] = try mongoProxy.readAll()
        return makeResponse(status: .ok, response: matchingDocuments)
    } catch {
        NSLog("readAll failed: \(error.localizedDescription)")
        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": readAll failed")
    }
}

func processUpdate<D: DataType>(path: String,
                                mongoProxy: MongoProxy,
                                operand: D,
                                type: D.Type,
                                on eventLoop: EventLoop) -> HTTPResponse {
    do {
        if try mongoProxy.replace(document: operand) {
            return makeResponse(status: .ok, response: operand)
        } else {
            return makeErrorResponse(status: .notFound, error: nil, response: path + ": id \(operand.id) not found")
        }
    } catch {
        return makeErrorResponse(status: .badRequest, error: error, response: path + ": update failed")
    }
}

func processDelete(path: String,
                   mongoProxy: MongoProxy,
                   operand: String,
                   on eventLoop: EventLoop) -> HTTPResponse {
    do {
        let idToDelete = try jsonDecoder.decode(SingleID.self, from: operand)
        if try mongoProxy.delete(id: idToDelete.id) {
            return makeResponse(status: .ok, response: "deleted id \(idToDelete.id)")
        } else {
            return makeResponse(status: .notFound, response: "id \(idToDelete.id) not found")
        }
    } catch let error as DecodingError  {
        return makeErrorResponse(status: .badRequest, error: error, response: path + ": invalid operand")
    } catch {
        return makeErrorResponse(status: .internalServerError, error: error, response: path + ": delete failed")
    }
}

func processDrop(path: String,
                 mongoProxy: MongoProxy,
                 on eventLoop: EventLoop) -> HTTPResponse {
    do {
        try mongoProxy.drop()
        return makeResponse(status: .ok, response: "dropped")
    } catch {
        return makeErrorResponse(status: .badRequest, error: error, response: path)
    }
}
