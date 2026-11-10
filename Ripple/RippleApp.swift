//
//  RippleApp.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import SwiftUI
import SwiftData

@main
struct RippleApp: App {
    var body: some Scene {
        WindowGroup {
            // Task 2 (Kelsey): shows onboarding on first launch only.
            // Hooked up by Anthony while integrating Task 1 and Task 2.
            ContentView()
                .rippleOnboarding()
        }
        .modelContainer(for: [
            Habit.self,
            HabitCompletion.self,
            JournalEntry.self,
            UserPreferences.self
        ])
    }
}

