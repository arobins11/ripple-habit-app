//
//  Task1UITests.swift
//  RippleUITests
//
//  Task 1 — Duty 1.6
//  XCUITests for the main habit workflow (add → complete → undo)
//  and for habit name validation (empty and long names).
//
//  Each test makes its own habit with a random name and deletes it at the end,
//  so the tests don't depend on (or leave behind) other saved habits.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import Foundation
import XCTest

@MainActor
final class Task1UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    /// Duty 1.6: add a habit, check it off, undo it, then delete it.
    func testAddCompleteUndoHabit() throws {
        let app = launchApp()
        let name = "UI Test \(Int.random(in: 1000...9999))"

        // Add
        addHabit(named: name, in: app)
        let checkbox = app.buttons["checkbox-\(name)"]
        XCTAssertTrue(scrollUntilFound(checkbox, in: app),
                      "The new habit should appear on the Today screen")
        XCTAssertEqual(checkbox.label, "Complete \(name)")

        // Complete
        checkbox.tap()
        XCTAssertTrue(waitForLabel(of: checkbox, toBe: "Undo \(name)"),
                      "Tapping the checkbox should mark the habit complete")

        // Undo
        checkbox.tap()
        XCTAssertTrue(waitForLabel(of: checkbox, toBe: "Complete \(name)"),
                      "Tapping again should undo the completion")

        // Clean up
        deleteHabit(named: name, in: app)
        XCTAssertTrue(checkbox.waitForNonExistence(timeout: 5),
                      "The deleted habit should disappear")
    }

    /// Duty 1.6: empty, blank and too-long (over 60 characters) names can't be saved.
    func testHabitNameValidation() throws {
        let app = launchApp()

        app.buttons["addHabitButton"].tap()
        let field = app.textFields["habitNameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let save = app.buttons["saveHabitButton"]

        // Empty name
        XCTAssertFalse(save.isEnabled, "Save should be disabled with an empty name")

        // Only spaces
        field.tap()
        field.typeText("   ")
        XCTAssertFalse(save.isEnabled, "A name made of only spaces should not be saveable")

        // Too long (over 60 characters): Save is disabled and a message explains why.
        field.typeText(String(repeating: "a", count: 70))
        XCTAssertFalse(save.isEnabled, "Names over 60 characters should not be saveable")
        XCTAssertTrue(app.staticTexts["nameTooLongMessage"].waitForExistence(timeout: 3),
                      "The form should explain the 60-character limit")

        // Clear the field and type a normal name: Save turns back on.
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 80))
        field.typeText("Read 10 pages")
        XCTAssertTrue(save.isEnabled, "A normal name should be saveable")

        // Leave without saving
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["addHabitButton"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        skipOnboardingIfShown(app)
        XCTAssertTrue(app.buttons["addHabitButton"].waitForExistence(timeout: 5),
                      "The Today screen should be showing")
        return app
    }

    /// Once Task 2 is merged, a fresh simulator shows onboarding first.
    /// This walks through it using Task 2's accessibility identifiers.
    /// Before Task 2 is merged, onboarding never appears and this does nothing.
    private func skipOnboardingIfShown(_ app: XCUIApplication) {
        guard app.staticTexts["onboarding.welcomeTitle"].waitForExistence(timeout: 2) else {
            return
        }
        app.buttons["onboarding.continue"].tap()
        app.buttons["onboarding.focus.Fitness"].tap()
        app.buttons["onboarding.focusContinue"].tap()

        let habitsContinue = app.buttons["onboarding.habitsContinue"]
        XCTAssertTrue(habitsContinue.waitForExistence(timeout: 3))
        habitsContinue.tap()

        // Turn reminders off so the notification permission alert doesn't appear.
        let reminders = app.switches["onboarding.remindersToggle"]
        if reminders.waitForExistence(timeout: 3), reminders.value as? String == "1" {
            reminders.tap()
            if reminders.value as? String == "1" {
                reminders.switches.firstMatch.tap()
            }
        }
        app.buttons["onboarding.finish"].tap()
    }

    private func addHabit(named name: String, in app: XCUIApplication) {
        app.buttons["addHabitButton"].tap()

        let field = app.textFields["habitNameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)

        // Put the test habit in Morning (the top section) so it's near the top
        // of the list. Otherwise it goes in the routine for the current time of day.
        let morning = app.segmentedControls.buttons["Morning"]
        if morning.waitForExistence(timeout: 2) {
            morning.tap()
        }

        app.buttons["saveHabitButton"].tap()
    }

    private func deleteHabit(named name: String, in app: XCUIApplication) {
        let row = app.buttons["habitRow-\(name)"]
        XCTAssertTrue(scrollUntilFound(row, in: app))
        row.tap()

        let deleteButton = app.buttons["deleteHabitButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        // iOS reports the confirm button twice (the button and its container),
        // so tap the first match instead of expecting exactly one.
        let confirm = app.buttons.matching(identifier: "confirmDeleteHabitButton").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
    }

    /// The Today list only loads rows that are on screen, so a habit near the
    /// bottom may not exist yet. This scrolls down until the element appears.
    /// If it never does, it prints what IS on screen to the test log.
    private func scrollUntilFound(_ element: XCUIElement, in app: XCUIApplication,
                                  maxSwipes: Int = 8) -> Bool {
        if element.waitForExistence(timeout: 3) {
            return true
        }
        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }
        print("Could not find \(element). Screen contents:\n\(app.debugDescription)")
        return false
    }

    /// Waits until an element's accessibility label changes to the expected text.
    private func waitForLabel(of element: XCUIElement, toBe label: String,
                              timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
