//
//  Quote.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation

struct Quote: Codable, Equatable {
    let text: String
    let author: String

    enum CodingKeys: String, CodingKey {
        case text = "q"
        case author = "a"
    }
}
