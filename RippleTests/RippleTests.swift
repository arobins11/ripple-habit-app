//
//  RippleTests.swift
//  RippleTests
//
//  Created by Brendon Young on 10/26/26.
//

import XCTest
import SwiftData
@testable import Ripple

@MainActor
final class RippleTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            JournalEntry.self,
            UserPreferences.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testCreateHabit() throws {
        let habit = Habit(name: "Drink Water")

        context.insert(habit)
        try context.save()

        let habits = try context.fetch(
            FetchDescriptor<Habit>()
        )

        XCTAssertEqual(habits.count, 1)
        XCTAssertEqual(habits.first?.name, "Drink Water")
    }

    func testUpdateHabit() throws {
        let habit = Habit(name: "Drink Water")

        context.insert(habit)
        try context.save()

        habit.name = "Exercise"
        try context.save()

        let habits = try context.fetch(
            FetchDescriptor<Habit>()
        )

        XCTAssertEqual(habits.first?.name, "Exercise")
    }

    func testDeleteHabit() throws {
        let habit = Habit(name: "Drink Water")

        context.insert(habit)
        try context.save()

        context.delete(habit)
        try context.save()

        let habits = try context.fetch(
            FetchDescriptor<Habit>()
        )

        XCTAssertTrue(habits.isEmpty)
    }

    func testHabitCompletion() throws {
        let habit = Habit(name: "Exercise")
        context.insert(habit)

        let completion = HabitCompletion(
            habitID: habit.id
        )

        context.insert(completion)
        try context.save()

        let completions = try context.fetch(
            FetchDescriptor<HabitCompletion>()
        )

        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(
            completions.first?.habitID,
            habit.id
        )
    }

    func testJournalEntry() throws {
        let entry = JournalEntry(
            content: "Today was a good day.",
            mood: 4
        )

        context.insert(entry)
        try context.save()

        let entries = try context.fetch(
            FetchDescriptor<JournalEntry>()
        )

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.mood, 4)
        XCTAssertEqual(
            entries.first?.content,
            "Today was a good day."
        )
    }

    func testUserPreferences() throws {
        let preferences = UserPreferences(
            focusArea: "Fitness",
            preferredReminderHour: 8,
            preferredReminderMinute: 30,
            hasCompletedOnboarding: true
        )

        context.insert(preferences)
        try context.save()

        let saved = try context.fetch(
            FetchDescriptor<UserPreferences>()
        )

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.focusArea, "Fitness")
        XCTAssertEqual(saved.first?.preferredReminderHour, 8)
        XCTAssertTrue(
            saved.first?.hasCompletedOnboarding == true
        )
    }
}
