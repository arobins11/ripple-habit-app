//
//  HabitSchedule.swift
//  Ripple
//
//  Task 1 — Duty 1.3 / 1.4 ("Only show weekday-specific habits on their scheduled days")
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

    /// Short list of the picked days, e.g. "Mon, Wed, Fri". nil for daily habits.
    var weekdaySummary: String? {
        guard frequency == HabitFrequency.specificWeekdays, !weekdays.isEmpty else {
            return nil
        }
        if Set(weekdays) == Set(1...7) {
            return "Every day"
        }
        let names = Calendar.current.shortWeekdaySymbols   // Sun, Mon, ...
        return weekdays
            .sorted()
            .filter { (1...7).contains($0) }
            .map { names[$0 - 1] }
            .joined(separator: ", ")
    }

    /// The reminder time, e.g. "8:30 AM". nil when the reminder is off.
    var reminderTimeText: String? {
        guard reminderEnabled,
              let time = Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute,
                                               second: 0, of: Date()) else {
            return nil
        }
        return time.formatted(date: .omitted, time: .shortened)
    }
}
