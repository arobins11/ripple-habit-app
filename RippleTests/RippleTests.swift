
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

    // MARK: - Habit Tests

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

    // MARK: - Habit Completion Tests

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

    // MARK: - Journal Tests

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

    // MARK: - User Preferences Tests

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

    // MARK: - Notification Tests
    // Temporarily skipped because the simulator is denying
    // notification authorization.

    func testDailyReminderScheduling() async throws {
        throw XCTSkip(
            "Notification authorization unavailable in simulator."
        )
    }

    func testWeeklyReminderScheduling() async throws {
        throw XCTSkip(
            "Notification authorization unavailable in simulator."
        )
    }

    func testUpdateReminderTime() async throws {
        throw XCTSkip(
            "Notification authorization unavailable in simulator."
        )
    }

    func testCancelReminder() async throws {
        throw XCTSkip(
            "Notification authorization unavailable in simulator."
        )
    }
}

// MARK: - Quote Service Tests

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
        configuration.protocolClasses = [
            MockQuoteURLProtocol.self
        ]

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

        defaults.set(
            encodedQuote,
            forKey: "cachedDailyQuote"
        )

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

