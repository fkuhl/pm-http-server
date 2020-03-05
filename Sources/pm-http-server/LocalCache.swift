//
//  LocalCache.swift
//  
//
//  Created by Frederick Kuhl on 3/2/20.
//

import Foundation
import Logging
import PMDataTypes
import HTTP

/**
 While this is named 'LocalCache' in fact we cache nothing locally, to avoid worrying about threads.
 The only truth is the DB, and every operation begins by consulting it.
 Eventually we'll find ways to employ MongoDB's querying capabilities.
 For now, "Premature optimization is the root of all evil."
 */

class LocalCache {
    private var mongoProxyStore: ThreadSpecificVariable<MongoProxy>? = nil
    
    // MARK: - Singleton
    static let sharedInstance = LocalCache()
    private init() {}

    private func getCurrentMongoProxy() throws -> MongoProxy {
        if let threadSpecificVariable = mongoProxyStore,
            let currentProxy = threadSpecificVariable.currentValue {
            return currentProxy
        }
        let newProxy = MongoProxy()
        do {
            let count = try newProxy.count()
            logger.info("proxy found \(count) documents")
            var threadSpecificVariable = mongoProxyStore
            if threadSpecificVariable == nil {
                threadSpecificVariable = ThreadSpecificVariable<MongoProxy>()
            }
            threadSpecificVariable!.currentValue = newProxy
            mongoProxyStore = threadSpecificVariable
            return newProxy
        }
    }
    
    func readMember(id: Id) throws -> HTTPResponse {
        let indexedHouseholds = try getHouseholds()
        if let memberAndRelation = findMember(id: id, among: indexedHouseholds) {
            return makeResponse(status: .ok, response: memberAndRelation.0)
        } else {
            return makeResponse(status: .notFound, response: "id \(id) not found")
        }
    }
    
    private func getHouseholds() throws -> IndexedHouseholds {
        let rawHouseholds = try getCurrentMongoProxy().readAll()
        var index = IndexedHouseholds()
        rawHouseholds.forEach {
            index[$0.id] = $0
        }
        return index
    }
    
    //FIXME This probably can be accomplished with a Mongo query
    private func findMember(id: Id, among: IndexedHouseholds) -> (Member, HouseholdRelation)? {
        for hd in among.values {
            if id == hd.head.id { return (hd.head, .head) }
            if let spouse = hd.spouse {
                if id == spouse.id { return (spouse, .spouse) }
            }
            for other in hd.others {
                if id == other.id { return (other, .other) }
            }
        }
        return nil
    }
    
    //FIXME a Mongo query?
    func readAllMembers() throws -> HTTPResponse {
        let rawHouseholds = try getCurrentMongoProxy().readAll()
        var members = [Member]()
        for hd in rawHouseholds {
            members.append(hd.head)
            if let spouse = hd.spouse { members.append(spouse) }
            members.append(contentsOf: hd.others)
        }
        return makeResponse(status: .ok, response: members)
    }
    
    //TODO This chokes if you try to change the household.
    func update(member: Member, on: EventLoop) throws -> HTTPResponse {
        let households = try getHouseholds()
        guard let old = findMember(id: member.id, among: households) else {
            return makeResponse(status: .notFound, response: "id \(member.id) not found")
        }
        guard old.0.household == member.household else {
            return makeResponse(status: .badRequest, response: "updated member household, \(member.household), differs from current household, \(old.0.household)")
        }
        guard let householdToUpdate = households[member.household] else {
            return makeResponse(status: .internalServerError, response: "household \(member.household) not recognized")
        }
        var editedHousehold = householdToUpdate
        switch old.1 {
        case .head:
            editedHousehold.head = member
        case .spouse:
            editedHousehold.spouse? = member
        case .other:
            var newOthers = editedHousehold.others
            for i in 0..<newOthers.count { //yeah, I'm writing Fortran in Swift
                if newOthers[i].id == member.id {
                    newOthers[i] = member
                    break
                }
            }
            editedHousehold.others = newOthers
        }
        let succeeded = try getCurrentMongoProxy().replace(document: editedHousehold)
        if succeeded {
            return makeResponse(status: .ok, response: member)
        } else {
            return makeResponse(status: .internalServerError, response: "update failed")
        }
    }
    
    func createHousehold(data: HouseholdDocument, on: EventLoop) throws -> HTTPResponse {
        var storedHousehold = data
        if let id = try getCurrentMongoProxy().add(dataValue: data) {
            storedHousehold.id = id
            return makeResponse(status: .ok, response: storedHousehold.id)
        } else {
            return makeResponse(status: .internalServerError, response: "something inexplicable occurred on create")
        }
    }
    
    func readHousehold(id: Id) throws -> HTTPResponse {
        if let household = try getCurrentMongoProxy().read(id: id) {
            return makeResponse(status: .ok, response: household)
        } else {
            return makeResponse(status: .notFound, response: "Household \(id) not found")
        }
    }
    
    func readAllHouseholds() throws -> HTTPResponse {
        let households = try getCurrentMongoProxy().readAll()
        return makeResponse(status: .ok, response: households)
    }
    
    func update(household: HouseholdDocument, on: EventLoop) throws -> HTTPResponse {
        if try getCurrentMongoProxy().replace(document: household) {
            return makeResponse(status: .ok, response: household)
        } else {
            return makeResponse(status: .notFound, response: "Household \(household.id) not found")
        }
    }
    
    func drop() throws -> HTTPResponse {
        try getCurrentMongoProxy().drop()
        return makeResponse(status: .ok, response: "dropped")
    }
    
    /**
     HouseholdDocuments indexed by HouseholdDcouemtn Id
     */
    typealias IndexedHouseholds = [Id : HouseholdDocument]
    
    private enum HouseholdRelation {
        case head
        case spouse
        case other
    }

}
