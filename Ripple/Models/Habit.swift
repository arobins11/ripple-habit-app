//
//  Habit.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var routine: String
    var frequency: String
    var weekdays: [Int]
    var icon: String
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var sortOrder: Int

    init(
        name: String,
        routine: String = "Morning",
        frequency: String = "Daily",
        weekdays: [Int] = [],
        icon: String = "checkmark.circle",
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.routine = routine
        self.frequency = frequency
        self.weekdays = weekdays
        self.icon = icon
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.sortOrder = sortOrder
    }
}
