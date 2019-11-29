//
//  Address.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

struct Address: DataType {
    var id: Id
    var value: AddressValue
}

struct AddressValue: ValueType {
    var address: String
    var address2: String?
    var city: String
    var state: String?
    var postalCode: String
    var country: String?
    var eMail: String?
    var homePhone: String?
}
