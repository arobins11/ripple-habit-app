//
//  JournalEntry.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var content: String
    var mood: Int

    init(
        date: Date = Date(),
        content: String = "",
        mood: Int = 3
    ) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.mood = mood
    }
}
