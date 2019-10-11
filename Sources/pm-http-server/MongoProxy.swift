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
            NSLog("insert returned id \(result.insertedId) of type \(result.insertedId.bsonType)")
            return Member(id: 0, value: memberValue)
        }
        NSLog("add returned nil")
        return nil
    }
    
//    func read(id: Int) -> Member? {
//        return members[id]
//    }
//
//    func readAll() -> [Member] {
//        return Array(members.values)
//    }
//
//    func update(member: Member) -> Member? {
//        if members.keys.contains(member.id) {
//            members[member.id] = member
//            return member
//        } else {
//            return nil
//        }
//    }
//
//    func delete(id: Int) -> Member? {
//        return members.removeValue(forKey: id)
//    }
}
