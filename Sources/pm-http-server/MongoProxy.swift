//
//  MongoClient.swift
//  
//
//  Created by Frederick Kuhl on 10/11/19.
//

import HTTP
import MongoSwift

class MongoProxy {
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
        //TODO magic name
        NSLog("about to retrieve collection")
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
    
    func read(id: String) throws -> Member? {
        //TODO magic name
        NSLog("about to retrieve collection")
        let memberCollection = db?.collection("Members")
        //TODO magic name!!!
        guard let idValue = ObjectId(id) else {
            NSLog("string \(id) didn't produce valid Object id")
            return nil
        }
        let query: Document = ["_id": idValue]
        NSLog("about to query for id \(idValue)")
        let matched = try memberCollection!.find(query)
        if let matchingDocument = matched.next() {
            NSLog("read found id \(matchingDocument["_id"] ?? "nuthin"): '\(matchingDocument)'")
            let trimmed = matchingDocument.dropFirst()
            NSLog("Trimmed: '\(trimmed)'")
            let value = try BSONDecoder().decode(Member.Value.self, from: matchingDocument)
            return  Member(id: id, value: value)
        }
        return nil
    }

    func readAll() throws -> [Member] {
        //TODO magic name
        NSLog("about to retrieve collection")
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

//    func update(member: Member) -> Member? {
//        if members.keys.contains(member.id) {
//            members[member.id] = member
//            return member
//        } else {
//            return nil
//        }
//    }

//    func delete(id: Int) -> Member? {
//        return members.removeValue(forKey: id)
//    }
}
