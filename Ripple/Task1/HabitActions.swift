//
//  HabitActions.swift
//  Ripple
//
//  Task 1 — Duty 1.2 / 1.5
//  Shared save/delete helpers so every screen changes habits the same way.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): "Build Task 1 piece 1 for our Ripple habit app —
//  a Today screen with morning/afternoon/evening routines and add/edit/delete,
//  saved with our team's existing SwiftData Habit model."
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
