//
//  Member.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import Foundation

enum MemberStatus: String, Decodable {
    case NONCOMMUNING
    case COMMUNING
}

struct Member: Decodable {
    let id:Int
    
    struct Public: Decodable {
        let givenName: String
        let familyName: String
        let memberStatus: MemberStatus
    }
}
