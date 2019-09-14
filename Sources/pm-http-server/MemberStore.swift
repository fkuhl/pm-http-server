//
//  MemberStore.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/13/19.
//

import Foundation


class MemberStore {
    static var sharedInstance = MemberStore()

    var nextSerial = 1776;
    var members = [Int: Member]()
    
    func add(memberValue: Member.Value) -> Member {
        let newOne = Member(id: nextSerial, value: memberValue)
        members[newOne.id] = newOne
        nextSerial += 1
        return newOne
    }
}
