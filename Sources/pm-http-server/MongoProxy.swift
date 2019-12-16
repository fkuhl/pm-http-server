//
//  MongoClient.swift
//  
//
//  Created by Frederick Kuhl on 10/11/19.
//

import Foundation
import MongoSwift


public enum CollectionName: String {
    case members = "Members"
    case households = "Households"
    case addresses = "Addresses"
}


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
        client = try! MongoClient("mongodb://localhost:27017")
        db = client.db("PeriMeleon")
        collection = db.collection(collectionName.rawValue)
    }
    
    func count() throws -> Int {
        do {
            return try collection.count()
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func add<V: ValueType>(dataValue: V) throws -> Id? {
        NSLog("about to encode doc")
        do {
            let document = try Document(fromJSON: dataValue.asJSONData())
            NSLog("about to insert")
            if let result = try collection.insertOne(document) {
                //For insertedId, MongoSwift returns a BSONValue rather than ObjectId,
                //so must convert to String sketchily
                let idAsString = "\(result.insertedId)"
                NSLog("insert returned id \(result.insertedId) of type \(result.insertedId.bsonType)")
                return idAsString
            }
            NSLog("add returned nil")
            return nil
        } catch let error as UserError {
            throw MongoProxyError.jsonEncodingError(error)
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
        
    func read<V: ValueType>(id: Id) throws -> V? {
        guard let idValue = ObjectId(id) else {
            throw MongoProxyError.invalidId(id)
        }
        do {
            let query: Document = ["_id": idValue]
            NSLog("about to query for id \(idValue)")
            let matched = try collection.find(query)
            if let matchingDocument = matched.next() {
                NSLog("read found id \(matchingDocument["_id"] ?? "nuthin"): '\(matchingDocument)'")
                //Big Fat Assumption: the Document structure has ID as first element
                let shornOfId = matchingDocument.dropFirst()
                NSLog("Shorn: '\(shornOfId)'")
                let value = try decoder.decode(V.self, from: matchingDocument)
                return  value
            }
            return nil
        } catch let error as DecodingError {
            throw MongoProxyError.jsonDecodingError(error)
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }

    func readAll<D: DataType>() throws -> [D] {
        do {
            let everythingQuery: Document = []
            let matched = try collection.find(everythingQuery)
            var result = [D]()
            while let matchingDocument = matched.next() {
                NSLog("read found id \(matchingDocument["_id"] ?? "nuthin"): '\(matchingDocument)'")
                if let idElement = matchingDocument["_id"], idElement.bsonType == .objectId {
                    let trimmed = matchingDocument.dropFirst()
                    let value = try decoder.decode(D.V.self, from: trimmed)
                    result.append(D(id: "\(idElement)", value: value))
                }
            }
            return result
        } catch let error as DecodingError {
            throw MongoProxyError.jsonDecodingError(error)
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func replace<D: DataType>(document: D) throws -> Bool {
        guard let idValue = ObjectId(document.id) else {
            throw MongoProxyError.invalidId(document.id)
        }
        do {
            let filter: Document = ["_id": idValue]
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
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func delete(id: Id) throws -> Bool{
        guard let idValue = ObjectId(id) else {
            throw MongoProxyError.invalidId(id)
        }
        do {
            let filter: Document = ["_id": idValue]
            NSLog("about to delete \(id)")
            let rawResult = try collection.deleteOne(filter)
            guard let result = rawResult else {
                return false
            }
            return result.deletedCount == 1
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
    
    func drop() throws {
        do {
            try collection.drop()
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
}

public enum MongoProxyError: Error, CustomStringConvertible {
    //MongoSwift can't make this string into an ID
    case invalidId(String)
    //Error encoding JSON into BSON Document to pass to MongoSwift
    case jsonEncodingError(Error)
    //Error decoding stuff received from MongoSwift into JSON
    case jsonDecodingError(Error)
    //Other error generated by MongoSwift
    case mongoSwiftError (Error)
    
    public var description: String {
        switch self {
        case .invalidId (let description):
            return "Invalid ID: '\(description)'"
        case .jsonEncodingError(let underlying):
            return "JSON encoding error '\(underlying)'"
        case .jsonDecodingError(let underlying):
            return "JSON encoding error '\(underlying)'"
        case .mongoSwiftError(let underlying):
            return "JSON encoding error '\(underlying)'"
        }
    }

    
}
