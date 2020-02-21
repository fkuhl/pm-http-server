//
//  MongoClient.swift
//  
//
//  Created by Frederick Kuhl on 10/11/19.
//

import Foundation
import MongoSwift
import PMDataTypes

class MongoProxy {
    private let client: MongoClient
    private let db: MongoDatabase
    private let collection: MongoCollection<Document>
    private let decoder: BSONDecoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let d = BSONDecoder()
        d.dateDecodingStrategy = .formatted(formatter)
        return d
    }()
    
    /**
     Sets up the structures for the proxy.
     This succeeds even if there is no DB server to connect to.
     So 'twould be a good idea to use, say, count() to check the connection.
     */
    init(collectionName: CollectionName) {
        #if os(OSX)
            client = try! MongoClient("mongodb://localhost:27017")
        #else
            client = try! MongoClient("mongodb://pm-http-server_db_1:27017")
        #endif
        db = client.db("PeriMeleon")
        collection = db.collection(collectionName.rawValue)
    }
    
    func count() throws -> Int {
        do {
            return try collection.countDocuments()
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func add<V: ValueType>(dataValue: V) throws -> Id? {
        NSLog("about to encode doc")
        do {
            let document = try Document(fromJSON: dataValue.asJSONData())
            NSLog("about to insert")
            if let result = try collection.insertOne(document) {
                let idAsBson = result.insertedId
                guard idAsBson.type == BSONType.objectId else {
                    throw MongoProxyError.invalidId("returned id of unexpected type \(idAsBson.type)")
                }
                let idAsObjectId = idAsBson.objectIdValue
                NSLog("insert returned id \(idAsObjectId?.hex ?? "nada") of type \(idAsBson.type)")
                return idAsObjectId?.hex
            }
            NSLog("add returned nil")
            return nil
        } catch let error as UserError {
            throw MongoProxyError.jsonEncodingError(error)
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
        
    func read<V: ValueType>(id: Id) throws -> V? {
        guard let idValue = ObjectId(id) else {
            throw MongoProxyError.invalidId(id)
        }
        do {
            let idBson = BSON.objectId(idValue)
            let query: Document = ["_id": idBson]
            NSLog("about to query for id \(idValue)")
            let matched = try collection.find(query)
            if let matchingDocument = matched.next() {
                if let idBson = matchingDocument["_id"], let idAsObjectId = idBson.objectIdValue {
                    let idString = idAsObjectId.hex
                    NSLog("read found id \(idString): '\(matchingDocument)'")
                    //Big Fat Assumption: the Document structure has ID as first element
                    let shornOfId = matchingDocument.dropFirst()
                    NSLog("Shorn: '\(shornOfId)'")
                    let value = try decoder.decode(V.self, from: matchingDocument)
                    return  value
                }
            }
            return nil
        } catch let error as DecodingError {
            throw MongoProxyError.jsonDecodingError(error)
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }

    func readAll<D: DataType>() throws -> [D] {
        do {
            let everythingQuery: Document = [:]
            let matched = try collection.find(everythingQuery)
            var result = [D]()
            var docNo = 0
            while let matchingDocument = matched.next() {
                if let idBson = matchingDocument["_id"], let idAsObjectId = idBson.objectIdValue {
                    docNo += 1
                    let trimmed = matchingDocument.dropFirst()
                    do {
                        let value = try decoder.decode(D.V.self, from: trimmed)
                        result.append(D.init(id: "\(idAsObjectId.hex)", value: value))
                    } catch {
                        NSLog("doc no \(docNo): read found id \(idAsObjectId.hex): '\(matchingDocument)'")
                        NSLog("decode from BSON failed: \(error.localizedDescription)")
                        print(error)
                    }
                } else {
                    NSLog("can't extract id for \(matchingDocument)")
                }
            }
            NSLog("proxy read \(result.count) from collection \(collection.name)")
            return result
        } catch let error as DecodingError {
            throw MongoProxyError.jsonDecodingError(error)
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func replace<D: DataType>(document: D) throws -> Bool {
        guard let idValue = ObjectId(document.id) else {
            throw MongoProxyError.invalidId(document.id)
        }
        do {
            let filter: Document = ["_id": BSON.objectId(idValue)]
            let documentToUpdateTo = try Document(fromJSON: document.value.asJSONData())
            NSLog("about to update \(document.id)")
            let rawResult = try collection.replaceOne(
                filter: filter,
                replacement: documentToUpdateTo,
                options: ReplaceOptions(upsert: false)) //don't insert if not present
            guard let result = rawResult else {
                return false
            }
            return result.matchedCount == 1
        } catch let error as UserError {
            throw MongoProxyError.jsonEncodingError(error)
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func delete(id: Id) throws -> Bool{
        guard let idValue = ObjectId(id) else {
            throw MongoProxyError.invalidId(id)
        }
        do {
            let filter: Document = ["_id": BSON.objectId(idValue)]
            NSLog("about to delete \(id)")
            let rawResult = try collection.deleteOne(filter)
            guard let result = rawResult else {
                return false
            }
            return result.deletedCount == 1
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func drop() throws {
        do {
            try collection.drop()
        } catch let error as MongoError {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
}


public enum MongoProxyError: Error, LocalizedError {
    //MongoSwift can't make this string into an ID
    case invalidId(String)
    //Error encoding JSON into BSON Document to pass to MongoSwift
    case jsonEncodingError(Error)
    //Error decoding stuff received from MongoSwift into JSON
    case jsonDecodingError(Error)
    //Other error generated by MongoSwift
    case mongoSwiftError (MongoError)
    
    public var localizedDescription: String {
        switch self {
        case .invalidId (let description):
            return "Invalid ID: '\(description)'"
        case .jsonEncodingError(let underlying):
            return "JSON encoding error '\(underlying.localizedDescription)'"
        case .jsonDecodingError(let underlying): 
            return "JSON decoding error '\(underlying)'"
        case .mongoSwiftError(let underlying):
            switch underlying.self {
            case let runtimeError as RuntimeError:
                return "Mongo Swift RuntimeError: \(runtimeError.localizedDescription)"
            case let serverError as ServerError:
                return "MongoSwift ServerError: \(serverError.localizedDescription)"
            case let userError as UserError:
                return "Mongo Swift UserError: \(userError.localizedDescription)"
            default:
                return "Mongo Swift other error: \(underlying.localizedDescription)"
            }
        }
    }

    
}
