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
    
    func read(id: Int) -> Member? {
        return members[id]
    }
    
    func readAll() -> [Member] {
        return Array(members.values)
    }
    
    func update(member: Member) -> Member? {
        if members.keys.contains(member.id) {
            members[member.id] = member
            return member
        } else {
            return nil
        }
    }
    
    func delete(id: Int) -> Member? {
        return members.removeValue(forKey: id)
    }
}
