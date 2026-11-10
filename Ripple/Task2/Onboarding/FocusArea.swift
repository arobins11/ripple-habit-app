//
//  FocusArea.swift
//  Ripple
//
//  Task 2 — Duty 2.1
//  The four focus areas offered during onboarding and the starter
//  habits suggested for each one.
//

import Foundation

/// A habit suggested during onboarding. It only becomes a real `Habit`
/// (the shared SwiftData model) when the user finishes onboarding.
struct StarterHabit: Identifiable, Hashable {
    var id: String { name }
    let name: String
    /// Must match the routine names used by the Today screen:
    /// "Morning", "Afternoon" or "Evening".
    let routine: String
    /// An SF Symbols name.
    let icon: String
}

/// The focus areas from the proposal. The raw value is what gets saved
/// in `UserPreferences.focusArea`.
enum FocusArea: String, CaseIterable, Identifiable {
    case betterSleep = "Better Sleep"
    case moreEnergy = "More Energy"
    case focus = "Focus"
    case fitness = "Fitness"

    var id: String { rawValue }

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .betterSleep: "Wind down and wake up rested"
        case .moreEnergy: "Feel less tired during the day"
        case .focus: "Get your most important work done"
        case .fitness: "Move your body every day"
        }
    }

    var icon: String {
        switch self {
        case .betterSleep: "moon.zzz.fill"
        case .moreEnergy: "bolt.fill"
        case .focus: "scope"
        case .fitness: "figure.run"
        }
    }

    var starterHabits: [StarterHabit] {
        switch self {
        case .betterSleep:
            [
                StarterHabit(name: "Get morning sunlight", routine: "Morning", icon: "sun.max"),
                StarterHabit(name: "No caffeine after 2 PM", routine: "Afternoon", icon: "cup.and.saucer"),
                StarterHabit(name: "No screens before bed", routine: "Evening", icon: "moon.zzz")
            ]
        case .moreEnergy:
            [
                StarterHabit(name: "Drink a glass of water", routine: "Morning", icon: "drop"),
                StarterHabit(name: "Eat a healthy breakfast", routine: "Morning", icon: "fork.knife"),
                StarterHabit(name: "Take a 10-minute walk", routine: "Afternoon", icon: "figure.walk")
            ]
        case .focus:
            [
                StarterHabit(name: "Plan your top 3 tasks", routine: "Morning", icon: "list.bullet"),
                StarterHabit(name: "25-minute focus session", routine: "Afternoon", icon: "timer"),
                StarterHabit(name: "Read 10 pages", routine: "Evening", icon: "book")
            ]
        case .fitness:
            [
                StarterHabit(name: "Stretch for 5 minutes", routine: "Morning", icon: "figure.flexibility"),
                StarterHabit(name: "Workout", routine: "Afternoon", icon: "dumbbell"),
                StarterHabit(name: "Prepare tomorrow's gym bag", routine: "Evening", icon: "bag")
            ]
        }
    }
}
