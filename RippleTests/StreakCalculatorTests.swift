
import XCTest
@testable import Ripple

final class StreakCalculatorTests: XCTestCase {

    let calendar = Calendar(identifier: .gregorian)

    func makeDate(_ day: Int) -> Date {
        calendar.date(
            from: DateComponents(year: 2026, month: 10, day: day)
        )!
    }

    func testThreeDayStreak() {
        let result = StreakCalculator.calculate(
            completionDates: [
                makeDate(5), makeDate(6), makeDate(7)
            ],
            scheduledWeekdays: Set(1...7),
            today: makeDate(7),
            calendar: calendar
        )

        XCTAssertEqual(result.currentStreak, 3)
        XCTAssertEqual(result.bestStreak, 3)
    }

    func testMissedDayBreaksStreak() {
        let result = StreakCalculator.calculate(
            completionDates: [
                makeDate(5), makeDate(7)
            ],
            scheduledWeekdays: Set(1...7),
            today: makeDate(7),
            calendar: calendar
        )

        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertEqual(result.bestStreak, 1)
    }

    func testNoCompletions() {
        let result = StreakCalculator.calculate(
            completionDates: [],
            scheduledWeekdays: Set(1...7),
            today: makeDate(7),
            calendar: calendar
        )

        XCTAssertEqual(result.currentStreak, 0)
        XCTAssertEqual(result.bestStreak, 0)
    }

    func testSevenDayMilestone() {
        let result = StreakCalculator.calculate(
            completionDates: (1...7).map { makeDate($0) },
            scheduledWeekdays: Set(1...7),
            today: makeDate(7),
            calendar: calendar
        )

        XCTAssertEqual(result.currentStreak, 7)
        XCTAssertEqual(result.reachedMilestone, 7)
    }
}

