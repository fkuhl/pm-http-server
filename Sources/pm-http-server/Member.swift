//
//  Member.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import Foundation

enum MemberStatus: String, Encodable, Decodable {
    case NONCOMMUNING
    case COMMUNING
}

struct Member: Encodable, Decodable {
    let givenName: String
    let familyName: String
    let memberStatus: MemberStatus
    let dateJoined: Date
    let dateMarried: Date?
    var _id: MongoId?
    
    func asJSONData() -> Data  {
        return try! jsonEncoder.encode(self)
    }
    
    mutating func setId(newVal: MongoId) {
        _id = newVal
    }
    
}

