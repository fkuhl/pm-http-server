//
//  DataType.swift
//  Async
//
//  Created by Frederick Kuhl on 11/29/19.
//

import Foundation


typealias Id = String

protocol ValueType: Encodable, Decodable { }

extension ValueType {
    func asJSONData() -> Data  {
        return try! jsonEncoder.encode(self)
    }
}

protocol DataType: Encodable, Decodable {
    associatedtype V: ValueType
    
    var id: Id { get set }
    var value: V { get set }
    
    init(id: Id, value: V)
}
