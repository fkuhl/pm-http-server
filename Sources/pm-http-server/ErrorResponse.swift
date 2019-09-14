//
//  PeriMeleonResponse.swift
//  pm-http-server
//
//  Created by Frederick Kuhl on 9/12/19.
//

import Foundation

struct ErrorResponse: Codable {
    let error: String
    let response: String
}
