//
//  HabitCompletion.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation
import SwiftData

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    var completedAt: Date

    init(habitID: UUID, completedAt: Date = Date()) {
        self.id = UUID()
        self.habitID = habitID
        self.completedAt = completedAt
    }
}
