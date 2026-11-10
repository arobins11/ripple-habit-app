
import Foundation

struct StreakResult {
    let currentStreak: Int
    let bestStreak: Int
    let reachedMilestone: Int?
}

struct StreakCalculator {

    static let milestones = [7, 30, 100]

    static func calculate(
        completionDates: [Date],
        scheduledWeekdays: Set<Int> = Set(1...7),
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakResult {

        let completedDays = Set(
            completionDates.map {
                calendar.startOfDay(for: $0)
            }
        )

        guard !scheduledWeekdays.isEmpty else {
            return StreakResult(
                currentStreak: 0,
                bestStreak: 0,
                reachedMilestone: nil
            )
        }

        func isScheduled(_ date: Date) -> Bool {
            scheduledWeekdays.contains(
                calendar.component(.weekday, from: date)
            )
        }

        func previousScheduledDay(before date: Date) -> Date {
            var day = date

            for _ in 0..<7 {
                guard let previous = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: day
                ) else {
                    return day
                }

                day = previous

                if isScheduled(day) {
                    return day
                }
            }

            return day
        }

        // Calculate the best streak ever achieved.
        let sortedDays = completedDays
            .filter { isScheduled($0) }
            .sorted()

        var bestStreak = 0
        var runningStreak = 0
        var previousDay: Date?

        for date in sortedDays {
            if let previousDay {
                var day = previousDay
                var missedScheduledDay = false

                while let next = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: day
                ), next < date {
                    day = next

                    if isScheduled(day) &&
                        !completedDays.contains(day) {
                        missedScheduledDay = true
                    }
                }

                if missedScheduledDay {
                    runningStreak = 0
                }
            }

            runningStreak += 1
            bestStreak = max(bestStreak, runningStreak)
            previousDay = date
        }

        // Calculate the current streak.
        let currentDay = calendar.startOfDay(for: today)

        var day: Date

        if isScheduled(currentDay) &&
            completedDays.contains(currentDay) {
            day = currentDay
        } else {
            day = previousScheduledDay(before: currentDay)
        }

        var currentStreak = 0

        while completedDays.contains(day) {
            currentStreak += 1
            day = previousScheduledDay(before: day)
        }

        let milestone = milestones.contains(currentStreak)
            ? currentStreak
            : nil

        return StreakResult(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            reachedMilestone: milestone
        )
    }
}
