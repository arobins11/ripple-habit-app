//
//  UserPrefrences.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    var focusArea: String
    var preferredReminderHour: Int
    var preferredReminderMinute: Int
    var hasCompletedOnboarding: Bool
    var journalLockEnabled: Bool

    init(
        focusArea: String = "",
        preferredReminderHour: Int = 9,
        preferredReminderMinute: Int = 0,
        hasCompletedOnboarding: Bool = false,
        journalLockEnabled: Bool = false
    ) {
        self.focusArea = focusArea
        self.preferredReminderHour = preferredReminderHour
        self.preferredReminderMinute = preferredReminderMinute
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.journalLockEnabled = journalLockEnabled
    }
}
