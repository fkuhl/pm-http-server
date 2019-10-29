//
//  MongoClient.swift
//  
//
//  Created by Frederick Kuhl on 10/11/19.
//

import HTTP
import MongoSwift

typealias MongoId = String

class MongoProxy {
    //TODO: We're storing the event loop as if we were going to make the Mongo calls async
    //but, for now, the async barrier is above this in the call stack
    private let eventLoop: EventLoop
    private var client: MongoClient?
    private var db: MongoDatabase?
    
    init(on eventLoop: EventLoop) {
        do {
            self.eventLoop = eventLoop
            NSLog("about to connect to Mongo")
            self.client = try MongoClient("mongodb://localhost:27017")
            NSLog("connected")
            self.db = client!.db("PeriMeleon")
            NSLog("got DB")
        } catch {
            NSLog("blammo error \(error.localizedDescription)")
        }
    }
    
    func add(memberValue: Member.Value) throws -> Member? {
        NSLog("about to retrieve collection")
        //TODO magic name
        let memberCollection = db?.collection("Members")
        NSLog("about to encode doc")
        let document = try Document(fromJSON: memberValue.asJSONData())
        NSLog("about to insert")
        if let result = try memberCollection!.insertOne(document) {
            let idAsString = "\(result.insertedId)"
            NSLog("insert returned id \(result.insertedId) of type \(result.insertedId.bsonType)")
            return Member(id: idAsString, value: memberValue)
        }
        NSLog("add returned nil")
        return nil
    }
    
    func read(id: MongoId) throws -> Member? {
        NSLog("about to retrieve collection")
        //TODO magic name
        let memberCollection = db?.collection("Members")
        guard let idValue = ObjectId(id) else {
            throw MongoError.invalidId(id)
        }
        let query: Document = ["_id": idValue]
        NSLog("about to query for id \(idValue)")
        let matched = try memberCollection!.find(query)
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
        NSLog("about to retrieve collection")
        //TODO magic name
        let memberCollection = db?.collection("Members")
        let everythingQuery: Document = []
        let matched = try memberCollection!.find(everythingQuery)
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
        NSLog("about to replace doc")
        //TODO magic name
        let memberCollection = db?.collection("Members")
        guard let idValue = ObjectId(member.id) else {
            throw MongoError.invalidId(member.id)
        }
        let filter: Document = ["_id": idValue]
        let documentToUpdateTo = try Document(fromJSON: member.value.asJSONData())
        NSLog("about to update \(member.id)")
        let rawResult = try memberCollection?.replaceOne(
            filter: filter,
            replacement: documentToUpdateTo,
            options: ReplaceOptions(upsert: false)) //don't insert if not present
        guard let result = rawResult else {
            return false
        }
        return result.matchedCount == 1
    }
    
    func delete(id: MongoId) throws -> Bool{
        NSLog("about to delete doc")
        //TODO magic name
        let memberCollection = db?.collection("Members")
        guard let idValue = ObjectId(id) else {
            throw MongoError.invalidId(id)
        }
        let filter: Document = ["_id": idValue]
        NSLog("about to delete \(id)")
        let rawResult = try memberCollection?.deleteOne(filter)
        guard let result = rawResult else {
            return false
        }
        return result.deletedCount == 1
    }
    
    func drop() throws {
        NSLog("about to drop collection")
        //TODO magic name
        let memberCollection = db?.collection("Members")
        try memberCollection?.drop()
    }
}

enum MongoError: Error {
    case invalidId(String)
}
