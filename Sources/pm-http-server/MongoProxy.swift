//
//  MongoClient.swift
//  
//
//  Created by Frederick Kuhl on 10/11/19.
//

import Foundation
import MongoSwift

typealias MongoId = String

class MongoProxy {
    private let client: MongoClient
    private let db: MongoDatabase
    private let collection: MongoCollection<Document>
    
    /**
     Sets up the structures for the proxy.
     This succeeds even if there is no DB server to connect to.
     So 'twould be a good idea to use, say, count() to check the connection.
     */
    init(collectionName: String) {
        client = try! MongoClient("mongodb://localhost:27017")
        db = client.db("PeriMeleon")
        collection = db.collection(collectionName)
    }
    
    func count() throws -> Int {
        return try collection.count()
    }
    
    func add(memberValue: Member.Value) throws -> Member? {
        NSLog("about to encode doc")
        let document = try Document(fromJSON: memberValue.asJSONData())
        NSLog("about to insert")
        if let result = try collection.insertOne(document) {
            let idAsString = "\(result.insertedId)"
            NSLog("insert returned id \(result.insertedId) of type \(result.insertedId.bsonType)")
            return Member(id: idAsString, value: memberValue)
        }
        NSLog("add returned nil")
        return nil
    }
    
    func read(id: MongoId) throws -> Member? {
        guard let idValue = ObjectId(id) else {
            throw MongoError.invalidId(id)
        }
        let query: Document = ["_id": idValue]
        NSLog("about to query for id \(idValue)")
        let matched = try collection.find(query)
        if let matchingDocument = matched.next() {
            NSLog("read found id \(matchingDocument["_id"] ?? "nuthin"): '\(matchingDocument)'")
            let shornOfId = matchingDocument.dropFirst()
            NSLog("Shorn: '\(shornOfId)'")
            let value = try BSONDecoder().decode(Member.Value.self, from: matchingDocument)
            return  Member(id: id, value: value)
        }
        return nil
    }

    func readAll() throws -> [Member] {
        let everythingQuery: Document = []
        let matched = try collection.find(everythingQuery)
        var result = [Member]()
        while let matchingDocument = matched.next() {
            NSLog("read found id \(matchingDocument["_id"] ?? "nuthin"): '\(matchingDocument)'")
            if let idElement = matchingDocument["_id"], idElement.bsonType == .objectId {
                let trimmed = matchingDocument.dropFirst()
                let value = try BSONDecoder().decode(Member.Value.self, from: trimmed)
                result.append(Member(id: "\(idElement)", value: value))
            }
        }
        return result
    }
    
    func replace(member: Member) throws -> Bool {
        guard let idValue = ObjectId(member.id) else {
            throw MongoError.invalidId(member.id)
        }
        let filter: Document = ["_id": idValue]
        let documentToUpdateTo = try Document(fromJSON: member.value.asJSONData())
        NSLog("about to update \(member.id)")
        let rawResult = try collection.replaceOne(
            filter: filter,
            replacement: documentToUpdateTo,
            options: ReplaceOptions(upsert: false)) //don't insert if not present
        guard let result = rawResult else {
            return false
        }
        return result.matchedCount == 1
    }
    
    func delete(id: MongoId) throws -> Bool{
        guard let idValue = ObjectId(id) else {
            throw MongoError.invalidId(id)
        }
        let filter: Document = ["_id": idValue]
        NSLog("about to delete \(id)")
        let rawResult = try collection.deleteOne(filter)
        guard let result = rawResult else {
            return false
        }
        return result.deletedCount == 1
    }
    
    func drop() throws {
        try collection.drop()
    }
}

enum MongoError: Error {
    case invalidId(String)
}
