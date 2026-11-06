//
//  Routine.swift
//  Ripple
//
//  Task 1 — Duty 1.1 / 1.4
//  The three daily routines a habit can belong to.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import Foundation

/// Morning, afternoon, or evening.
///
/// `Habit.routine` is saved as plain text ("Morning", "Afternoon", "Evening"),
/// which matches the starter habits in Task 2's onboarding. This enum turns
/// that text into something safer to switch over in the UI.
enum Routine: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var id: String { rawValue }

    /// SF Symbol shown in the section header.
    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    /// Reads the routine text saved on a Habit.
    /// Unexpected text falls back to morning so the habit never disappears.
    init(savedValue: String) {
        self = Routine(rawValue: savedValue.capitalized) ?? .morning
    }

    /// The routine that matches the current time of day.
    /// Used as the default when adding a new habit.
    static var current: Routine {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case ..<12: return .morning
        case ..<17: return .afternoon
        default: return .evening
        }
    }
}
