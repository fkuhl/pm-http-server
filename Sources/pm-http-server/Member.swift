//
//  Member.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import Foundation

enum TransactionType: String, Encodable, Decodable {
    case BIRTH
    case PROFESSION
    case RECEIVED
    case SUSPENDED
    case SUSPENSION_LIFTED
    case EXCOMMUNICATED
    case RESTORED
    case DISMISSAL_PENDING
    case DISMISSED
    case REMOVED_ADMIN
    case DIED
}

struct Transaction: Encodable, Decodable {
    var index: Id
    var date: Date?
    var type: TransactionType
    var authority: String?
    var church: String?
    var comment: String?
}

enum ServiceType: String, Encodable, Decodable {
    case ORDAINED_TE
    case ORDAINED_RE
    case ORDAINED_DE
    case INSTALLED_TE
    case INSTALLED_RE
    case INSTALLED_DE
    case REMOVED
    case EMERITUS
    case HON_RETIRED
    case DEPOSED
}

struct Service: Encodable, Decodable {
    var index: Id
    var date: Date?
    var type: ServiceType
    var place: String?
    var comment: String?
}

enum Sex: String, Encodable, Decodable {
    case MALE
    case FEMALE
}

enum MemberStatus: String, Encodable, Decodable {
    case NONCOMMUNING
    case COMMUNING
    case ASSOCIATE
    case EXCOMMUNICATED
    case SUSPENDED
    case DISMISSAL_PENDING
    case DISMISSED
    case REMOVED
    case DEAD
    case PASTOR
}

enum MaritalStatus: String, Encodable, Decodable {
    case SINGLE
    case MARRIED
    case DIVORCED
}

struct Member: DataType {
    var id: Id
    var value: MemberValue
}

struct MemberValue: ValueType {
    var familyName: String
    var givenName: String
    var middleName: String?
    var previousFamilyName: String?
    var nameSuffix: String?
    var title: String?
    var nickName: String?
    var sex: Sex
    var dateOfBirth: Date?
    var placeOfBirth: String?
    var status: MemberStatus
    var resident: Bool
    var exDirectory: Bool
    var household: Id
    var tempAddress: Id?
    var transactions: [Transaction]
    var maritalStatus: MaritalStatus
    var spouse: String?
    var dateOfMarriage: Date?
    var divorce: String?
    var father: Id?
    var mother: Id?
    var eMail: String?
    var workEMail: String?
    var mobilePhone: String?
    var workPhone: String?
    var education: String?
    var employer: String?
    var baptism: String?
    var services: [Service]
    var dateLastChanged: Date?
}
