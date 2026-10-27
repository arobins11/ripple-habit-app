//
//  RippleTests.swift
//  RippleTests
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation
import XCTest
import SwiftData
import UserNotifications
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
    
    func testDailyReminderScheduling() async throws {
        let habit = Habit(
            name: "Drink Water",
            frequency: "Daily",
            reminderEnabled: true,
            reminderHour: 9,
            reminderMinute: 30
        )
        
        let service = NotificationService.shared
        
        // Clear reminders before testing
        service.cancelReminders(for: habit)
        
        // Schedule the daily reminder
        try await service.scheduleReminder(for: habit)
        
        // Give the notification center time to update
        try await Task.sleep(for: .milliseconds(500))
        
        // Get the scheduled notifications
        let requests = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
        
        let reminderID = "\(habit.id.uuidString)-daily"
        
        // Debugging information
        print("Pending notifications: \(requests.count)")
        print("Expected reminder ID: \(reminderID)")
        
        for request in requests {
            print("Found reminder: \(request.identifier)")
        }
        
        // Find the daily reminder
        let reminder = try XCTUnwrap(
            requests.first { $0.identifier == reminderID }
        )
        
        let trigger = try XCTUnwrap(
            reminder.trigger as? UNCalendarNotificationTrigger
        )
        
        // Verify the reminder time
        XCTAssertEqual(trigger.dateComponents.hour, 9)
        XCTAssertEqual(trigger.dateComponents.minute, 30)
        XCTAssertTrue(trigger.repeats)
        
        // Clean up after testing
        service.cancelReminders(for: habit)
    }
    
    // Test weekly reminders on selected weekdays
    func testWeeklyReminderScheduling() async throws {
        let habit = Habit(
            name: "Go to the Gym",
            frequency: "Weekly",
            weekdays: [2, 4, 6],
            reminderEnabled: true,
            reminderHour: 8,
            reminderMinute: 30
        )
        
        let service = NotificationService.shared
        defer { service.cancelReminders(for: habit) }
        
        try await service.scheduleReminder(for: habit)
        
        let requests = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
        
        let habitRequests = requests.filter {
            $0.identifier.hasPrefix(habit.id.uuidString + "-")
        }
        
        XCTAssertEqual(habitRequests.count, 3)
        
        let weekdays = habitRequests.compactMap {
            ($0.trigger as? UNCalendarNotificationTrigger)?
                .dateComponents.weekday
        }
        
        XCTAssertEqual(Set(weekdays), Set([2, 4, 6]))
        
        for request in habitRequests {
            let trigger = try XCTUnwrap(
                request.trigger as? UNCalendarNotificationTrigger
            )
            
            XCTAssertEqual(trigger.dateComponents.hour, 8)
            XCTAssertEqual(trigger.dateComponents.minute, 30)
            XCTAssertTrue(trigger.repeats)
        }
    }
    
    // Test changing an existing reminder time
    func testUpdateReminderTime() async throws {
        let habit = Habit(
            name: "Exercise",
            frequency: "Daily",
            reminderEnabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        
        let service = NotificationService.shared
        defer { service.cancelReminders(for: habit) }
        
        try await service.scheduleReminder(for: habit)
        
        habit.reminderHour = 11
        habit.reminderMinute = 45
        
        try await service.scheduleReminder(for: habit)
        
        let requests = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
        
        let reminderID = "\(habit.id.uuidString)-daily"
        
        let habitRequests = requests.filter {
            $0.identifier == reminderID
        }
        
        XCTAssertEqual(habitRequests.count, 1)
        
        let reminder = try XCTUnwrap(habitRequests.first)
        
        let trigger = try XCTUnwrap(
            reminder.trigger as? UNCalendarNotificationTrigger
        )
        
        XCTAssertEqual(trigger.dateComponents.hour, 11)
        XCTAssertEqual(trigger.dateComponents.minute, 45)
    }
    
    // Test disabling and canceling reminders
    func testCancelReminder() async throws {
        let habit = Habit(
            name: "Drink Water",
            frequency: "Daily",
            reminderEnabled: true
        )
        
        let service = NotificationService.shared
        defer { service.cancelReminders(for: habit) }
        
        try await service.scheduleReminder(for: habit)
        
        let before = await service.pendingReminderCount(for: habit)
        XCTAssertEqual(before, 1)
        
        habit.reminderEnabled = false
        
        try await service.scheduleReminder(for: habit)
        
        let after = await service.pendingReminderCount(for: habit)
        XCTAssertEqual(after, 0)
    }
}
    //
    // MARK: - Quote Service Tests
    //

    private final class MockQuoteURLProtocol: URLProtocol {

        static var responseData = Data()
        static var statusCode = 200
        static var shouldFail = false
        static var requestCount = 0

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(
            for request: URLRequest
        ) -> URLRequest {
            return request
        }

        override func startLoading() {
            Self.requestCount += 1

            if Self.shouldFail {
                client?.urlProtocol(
                    self,
                    didFailWithError: URLError(.notConnectedToInternet)
                )
                return
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: Self.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!

            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )

            client?.urlProtocol(
                self,
                didLoad: Self.responseData
            )

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    @MainActor
    final class QuoteServiceTests: XCTestCase {

        private var defaults: UserDefaults!
        private var session: URLSession!
        private var service: QuoteService!
        private var suiteName: String!

        override func setUp() {
            super.setUp()

            suiteName = "RippleQuoteTests-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName)!

            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockQuoteURLProtocol.self]
            session = URLSession(configuration: configuration)

            service = QuoteService(
                session: session,
                defaults: defaults
            )

            MockQuoteURLProtocol.responseData = Data(
                """
                [{"q":"Keep going.","a":"Test Author"}]
                """.utf8
            )
            MockQuoteURLProtocol.statusCode = 200
            MockQuoteURLProtocol.shouldFail = false
            MockQuoteURLProtocol.requestCount = 0
        }

        override func tearDown() {
            session.invalidateAndCancel()
            defaults.removePersistentDomain(forName: suiteName)

            service = nil
            session = nil
            defaults = nil

            super.tearDown()
        }

        func testSuccessfulQuoteFetch() async {
            let quote = await service.getDailyQuote()

            XCTAssertEqual(quote.text, "Keep going.")
            XCTAssertEqual(quote.author, "Test Author")
            XCTAssertEqual(MockQuoteURLProtocol.requestCount, 1)
        }

        func testDailyQuoteCaching() async {
            let firstQuote = await service.getDailyQuote()

            MockQuoteURLProtocol.shouldFail = true

            let secondQuote = await service.getDailyQuote()

            XCTAssertEqual(firstQuote, secondQuote)
            XCTAssertEqual(MockQuoteURLProtocol.requestCount, 1)
        }

        func testFallbackWhenNetworkFails() async {
            MockQuoteURLProtocol.shouldFail = true

            let quote = await service.getDailyQuote()

            XCTAssertEqual(
                quote.text,
                "Every day is a new opportunity to improve."
            )
            XCTAssertEqual(quote.author, "Ripple")
        }

        func testExpiredCacheFetchesNewQuote() async {
            let oldQuote = Quote(
                text: "Yesterday's quote",
                author: "Old Author"
            )

            let encodedQuote = try! JSONEncoder().encode(oldQuote)

            defaults.set(encodedQuote, forKey: "cachedDailyQuote")
            defaults.set(
                Calendar.current.date(
                    byAdding: .day,
                    value: -1,
                    to: Date()
                ),
                forKey: "cachedQuoteDate"
            )

            let quote = await service.getDailyQuote()

            XCTAssertEqual(quote.text, "Keep going.")
            XCTAssertEqual(quote.author, "Test Author")
            XCTAssertEqual(MockQuoteURLProtocol.requestCount, 1)
        }
    }


