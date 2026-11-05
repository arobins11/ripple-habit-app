//
//  HabitSchedule.swift
//  Ripple
//
//  Task 1 — Duty 1.4 ("Only show weekday-specific habits on their scheduled days")
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import Foundation

/// The text values saved in `Habit.frequency`.
/// These match what Task 4's NotificationService checks for.
enum HabitFrequency {
    static let daily = "Daily"
    static let specificWeekdays = "Weekly"
}

extension Habit {

    /// Whether this habit should appear on the given day.
    ///
    /// `weekdays` uses Calendar weekday numbers: 1 = Sunday … 7 = Saturday
    /// (the same numbers NotificationService schedules reminders with).
    /// A weekday habit with no days picked is treated as daily so it never vanishes.
    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        guard frequency == HabitFrequency.specificWeekdays, !weekdays.isEmpty else {
            return true
        }
        return weekdays.contains(calendar.component(.weekday, from: date))
    }
}
