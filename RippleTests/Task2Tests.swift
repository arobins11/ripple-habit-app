//
//  Task2Tests.swift
//  RippleTests
//
//  Task 2 — Duty 2.6
//  Unit tests for onboarding and the journal. Uses an in-memory store,
//  the same way RippleTests.swift does, so no real data is touched.
//

import Foundation
import XCTest
import SwiftData
@testable import Ripple

@MainActor
final class Task2OnboardingTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            JournalEntry.self,
            UserPreferences.self
        ])
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testEveryFocusAreaHasValidStarterHabits() {
        let validRoutines: Set<String> = ["Morning", "Afternoon", "Evening"]

        XCTAssertEqual(FocusArea.allCases.count, 4)

        for area in FocusArea.allCases {
            XCTAssertGreaterThanOrEqual(area.starterHabits.count, 3, "\(area)")

            for habit in area.starterHabits {
                XCTAssertFalse(habit.name.isEmpty)
                XCTAssertTrue(validRoutines.contains(habit.routine), habit.name)
            }

            let names = area.starterHabits.map(\.name)
            XCTAssertEqual(Set(names).count, names.count, "Duplicate starter habit in \(area)")
        }
    }

    func testOnboardingSavesPreferences() throws {
        try OnboardingSaver.save(
            focusArea: .fitness,
            starterHabits: [],
            remindersEnabled: true,
            reminderHour: 7,
            reminderMinute: 45,
            in: context
        )

        let saved = try context.fetch(FetchDescriptor<UserPreferences>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.focusArea, "Fitness")
        XCTAssertEqual(saved.first?.preferredReminderHour, 7)
        XCTAssertEqual(saved.first?.preferredReminderMinute, 45)
        XCTAssertEqual(saved.first?.hasCompletedOnboarding, true)
    }

    func testAllFourFocusAreasSaveCorrectly() throws {
        for area in FocusArea.allCases {
            try OnboardingSaver.save(
                focusArea: area,
                starterHabits: area.starterHabits,
                remindersEnabled: false,
                reminderHour: 9,
                reminderMinute: 0,
                in: context
            )

            let prefs = try context.fetch(FetchDescriptor<UserPreferences>())
            XCTAssertEqual(prefs.count, 1, "Only one preferences record should exist")
            XCTAssertEqual(prefs.first?.focusArea, area.rawValue)

            let habitNames = Set(try context.fetch(FetchDescriptor<Habit>()).map(\.name))
            for starter in area.starterHabits {
                XCTAssertTrue(habitNames.contains(starter.name), starter.name)
            }
        }
    }

    func testStarterHabitsGetReminderSettings() throws {
        let chosen = FocusArea.moreEnergy.starterHabits

        let created = try OnboardingSaver.save(
            focusArea: .moreEnergy,
            starterHabits: chosen,
            remindersEnabled: true,
            reminderHour: 8,
            reminderMinute: 15,
            in: context
        )

        XCTAssertEqual(created.count, chosen.count)

        for habit in created {
            XCTAssertTrue(habit.reminderEnabled)
            XCTAssertEqual(habit.reminderHour, 8)
            XCTAssertEqual(habit.reminderMinute, 15)
            XCTAssertEqual(habit.frequency, "Daily")
        }
    }

    func testOnlySelectedStarterHabitsAreAdded() throws {
        let firstOnly = Array(FocusArea.focus.starterHabits.prefix(1))

        try OnboardingSaver.save(
            focusArea: .focus,
            starterHabits: firstOnly,
            remindersEnabled: false,
            reminderHour: 9,
            reminderMinute: 0,
            in: context
        )

        let habits = try context.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(habits.map(\.name), firstOnly.map(\.name))
        XCTAssertEqual(habits.first?.reminderEnabled, false)
    }

    func testStarterHabitsAreAddedAfterExistingHabits() throws {
        let existing = Habit(name: "Existing habit", sortOrder: 5)
        context.insert(existing)
        try context.save()

        let created = try OnboardingSaver.save(
            focusArea: .betterSleep,
            starterHabits: FocusArea.betterSleep.starterHabits,
            remindersEnabled: false,
            reminderHour: 9,
            reminderMinute: 0,
            in: context
        )

        XCTAssertEqual(created.map(\.sortOrder), [6, 7, 8])
    }

    func testRunningOnboardingTwiceDoesNotDuplicateHabits() throws {
        for _ in 0..<2 {
            try OnboardingSaver.save(
                focusArea: .fitness,
                starterHabits: FocusArea.fitness.starterHabits,
                remindersEnabled: false,
                reminderHour: 9,
                reminderMinute: 0,
                in: context
            )
        }

        let habits = try context.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(habits.count, FocusArea.fitness.starterHabits.count)
    }

    func testPreferencesStoreReusesSingleRecord() throws {
        let first = try UserPreferencesStore.current(in: context)
        try context.save()
        let second = try UserPreferencesStore.current(in: context)

        XCTAssertTrue(first === second)
        XCTAssertEqual(try context.fetch(FetchDescriptor<UserPreferences>()).count, 1)
    }
}

@MainActor
final class Task2JournalTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            JournalEntry.self,
            UserPreferences.self
        ])
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testSaveCreatesTodaysEntry() throws {
        try JournalStore.save(content: "  Great day!  ", mood: 5, in: context)

        let entry = try XCTUnwrap(JournalStore.entry(on: Date(), in: context))
        XCTAssertEqual(entry.content, "Great day!")
        XCTAssertEqual(entry.mood, 5)
    }

    func testSavingTwiceOnSameDayUpdatesOneEntry() throws {
        try JournalStore.save(content: "First", mood: 2, in: context)
        try JournalStore.save(content: "Second", mood: 4, in: context)

        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.content, "Second")
        XCTAssertEqual(entries.first?.mood, 4)
    }

    func testDifferentDaysHaveSeparateEntries() throws {
        let today = Date()
        let yesterday = try XCTUnwrap(
            Calendar.current.date(byAdding: .day, value: -1, to: today)
        )

        try JournalStore.save(content: "Yesterday", mood: 1, on: yesterday, in: context)
        try JournalStore.save(content: "Today", mood: 5, on: today, in: context)

        XCTAssertEqual(try context.fetch(FetchDescriptor<JournalEntry>()).count, 2)
        XCTAssertEqual(try JournalStore.entry(on: yesterday, in: context)?.content, "Yesterday")
        XCTAssertEqual(try JournalStore.entry(on: today, in: context)?.content, "Today")
    }

    func testEveryMoodRatingIsSaved() throws {
        let calendar = Calendar.current

        for mood in MoodRating.allCases {
            let day = try XCTUnwrap(
                calendar.date(byAdding: .day, value: -mood.rawValue, to: Date())
            )
            try JournalStore.save(content: mood.label, mood: mood.rawValue, on: day, in: context)
            XCTAssertEqual(try JournalStore.entry(on: day, in: context)?.mood, mood.rawValue)
        }
    }

    func testOutOfRangeMoodIsClamped() throws {
        try JournalStore.save(content: "Too high", mood: 99, in: context)
        XCTAssertEqual(try JournalStore.entry(on: Date(), in: context)?.mood, 5)

        try JournalStore.save(content: "Too low", mood: -3, in: context)
        XCTAssertEqual(try JournalStore.entry(on: Date(), in: context)?.mood, 1)
    }

    func testNoEntryReturnsNil() throws {
        XCTAssertNil(try JournalStore.entry(on: Date(), in: context))
    }

    func testJournalLockSettingIsSaved() throws {
        let prefs = try UserPreferencesStore.current(in: context)
        prefs.journalLockEnabled = true
        try context.save()

        let saved = try context.fetch(FetchDescriptor<UserPreferences>())
        XCTAssertEqual(saved.first?.journalLockEnabled, true)
    }
}
