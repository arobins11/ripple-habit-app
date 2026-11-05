//
//  HabitActions.swift
//  Ripple
//
//  Task 1 — Duty 1.2 / 1.4 / 1.5
//  Shared save/delete helpers so every screen changes habits the same way.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import Foundation
import SwiftData

extension ModelContext {

    /// The sortOrder to give a habit added to the end of a routine.
    func nextSortOrder(for routine: Routine) -> Int {
        let allHabits = (try? fetch(FetchDescriptor<Habit>())) ?? []
        let highest = allHabits
            .filter { Routine(savedValue: $0.routine) == routine }
            .map(\.sortOrder)
            .max() ?? -1
        return highest + 1
    }

    /// Checks a habit off for the day, or undoes it if it was already checked.
    /// Each check-off is saved as a HabitCompletion, which Task 3 uses for
    /// streaks and charts. Returns true if the habit is now complete.
    @discardableResult
    func toggleCompletion(for habit: Habit, on date: Date = Date()) -> Bool {
        let habitID = habit.id
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }

        let completionsThatDay = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate {
                $0.habitID == habitID &&
                $0.completedAt >= startOfDay &&
                $0.completedAt < startOfNextDay
            }
        )
        let existing = (try? fetch(completionsThatDay)) ?? []

        if existing.isEmpty {
            insert(HabitCompletion(habitID: habitID, completedAt: date))
            try? save()
            return true
        } else {
            // Undo: remove that day's completion.
            for completion in existing {
                delete(completion)
            }
            try? save()
            return false
        }
    }

    /// Deletes a habit, its completion history, and any pending reminders,
    /// so nothing is left behind for the progress screen or notifications.
    func deleteHabitCompletely(_ habit: Habit) {
        NotificationService.shared.cancelReminders(for: habit)

        let habitID = habit.id
        let completionsForHabit = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.habitID == habitID }
        )
        if let completions = try? fetch(completionsForHabit) {
            for completion in completions {
                delete(completion)
            }
        }

        delete(habit)
        try? save()
    }
}
