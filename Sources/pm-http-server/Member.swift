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
    struct Value: Encodable, Decodable {
        let givenName: String
        let familyName: String
        let memberStatus: MemberStatus
        let dateJoined: Date
        let dateMarried: Date?

        func asJSONData() -> Data  {
            return try! jsonEncoder.encode(self)
        }
    }
    
    let id: MongoId
    let value: Value
}
