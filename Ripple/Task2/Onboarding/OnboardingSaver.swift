//
//  OnboardingSaver.swift
//  Ripple
//
//  Task 2 — Duty 2.2
//  Saves the user's onboarding choices using the shared models from
//  Task 4 (UserPreferences and Habit). Kept separate from the views so
//  it can be unit tested.
//

import Foundation
import SwiftData

/// Finds the app's single `UserPreferences` record, creating it if needed.
enum UserPreferencesStore {

    static func current(in context: ModelContext) throws -> UserPreferences {
        var descriptor = FetchDescriptor<UserPreferences>()
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let preferences = UserPreferences()
        context.insert(preferences)
        return preferences
    }
}

enum OnboardingSaver {

    /// Saves the focus area and reminder time, marks onboarding as done,
    /// and adds the chosen starter habits to the user's habit list.
    ///
    /// - Returns: The habits that were newly created. Habits whose name
    ///   already exists are skipped, so running onboarding twice does
    ///   not create duplicates.
    @discardableResult
    static func save(
        focusArea: FocusArea,
        starterHabits: [StarterHabit],
        remindersEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        in context: ModelContext
    ) throws -> [Habit] {

        let preferences = try UserPreferencesStore.current(in: context)
        preferences.focusArea = focusArea.rawValue
        preferences.preferredReminderHour = reminderHour
        preferences.preferredReminderMinute = reminderMinute
        preferences.hasCompletedOnboarding = true

        let existingHabits = try context.fetch(FetchDescriptor<Habit>())
        var existingNames = Set(existingHabits.map { $0.name.lowercased() })

        // New habits go after any habits the user already has.
        var nextSortOrder = (existingHabits.map(\.sortOrder).max() ?? -1) + 1

        var created: [Habit] = []

        for starter in starterHabits {
            let key = starter.name.lowercased()
            guard !existingNames.contains(key) else { continue }

            let habit = Habit(
                name: starter.name,
                routine: starter.routine,
                frequency: "Daily",
                icon: starter.icon,
                reminderEnabled: remindersEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                sortOrder: nextSortOrder
            )

            context.insert(habit)
            created.append(habit)
            existingNames.insert(key)
            nextSortOrder += 1
        }

        try context.save()
        return created
    }

    /// Asks for notification permission and schedules reminders for the
    /// new habits using Task 4's NotificationService.
    static func scheduleReminders(for habits: [Habit]) async {
        let remindedHabits = habits.filter(\.reminderEnabled)
        guard !remindedHabits.isEmpty else { return }

        let service = NotificationService.shared

        do {
            guard try await service.requestPermission() else { return }

            for habit in remindedHabits {
                try await service.scheduleReminder(for: habit)
            }
        } catch {
            print("Onboarding reminder error: \(error.localizedDescription)")
        }
    }
}
