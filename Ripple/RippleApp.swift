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
            ContentView()
        }
        .modelContainer(for: [
            Habit.self,
            HabitCompletion.self,
            JournalEntry.self,
            UserPreferences.self
        ])
    }
}

