//
//  NotificationService.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()

    private let notificationCenter =
        UNUserNotificationCenter.current()

    private init() {}

    // Ask the user for notification permission
    func requestPermission() async throws -> Bool {
        return try await notificationCenter
            .requestAuthorization(
                options: [.alert, .badge, .sound]
            )
    }

    // Schedule reminders for a habit
    func scheduleReminder(for habit: Habit) async throws {

        // Remove old reminders to prevent duplicates
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: reminderIDs(for: habit)
        )

        guard habit.reminderEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Ripple Reminder"
        content.body = "Time to complete: \(habit.name)"
        content.sound = .default

        if habit.frequency == "Daily" {

            var dateComponents = DateComponents()
            dateComponents.hour = habit.reminderHour
            dateComponents.minute = habit.reminderMinute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "\(habit.id.uuidString)-daily",
                content: content,
                trigger: trigger
            )

            try await notificationCenter.add(request)

        } else if habit.frequency == "Weekly" {
            
            for weekday in habit.weekdays {

                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = habit.reminderHour
                dateComponents.minute = habit.reminderMinute

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )

                let request = UNNotificationRequest(
                    identifier: "\(habit.id.uuidString)-\(weekday)",
                    content: content,
                    trigger: trigger
                )

                try await notificationCenter.add(request)
            }
        }
    }

    // Cancel reminders for a habit
    func cancelReminders(for habit: Habit) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: reminderIDs(for: habit)
        )
    }

    // Generate reminder identifiers
    private func reminderIDs(for habit: Habit) -> [String] {
        let dailyID = "\(habit.id.uuidString)-daily"

        let weekdayIDs = (1...7).map {
            "\(habit.id.uuidString)-\($0)"
        }

        return [dailyID] + weekdayIDs
    }

    // Check how many reminders are pending for a habit
    func pendingReminderCount(for habit: Habit) async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiers = Set(reminderIDs(for: habit))

        return requests.filter {
            identifiers.contains($0.identifier)
        }.count
    }

}
