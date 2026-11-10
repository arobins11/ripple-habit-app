//
//  Task2UITests.swift
//  RippleUITests
//
//  Task 2 — Duty 2.6
//  XCUITests for the onboarding flow and for saving a journal entry.
//
//  These need the one-line hook in RippleApp.swift:
//      ContentView().rippleOnboarding()
//

import Foundation
import XCTest

@MainActor
final class Task2UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-RippleResetOnboarding"]
        app.launch()

        // Welcome
        XCTAssertTrue(app.staticTexts["onboarding.welcomeTitle"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].tap()

        // Focus area — Continue is disabled until one is picked.
        let focusContinue = app.buttons["onboarding.focusContinue"]
        XCTAssertTrue(focusContinue.waitForExistence(timeout: 3))
        XCTAssertFalse(focusContinue.isEnabled)

        app.buttons["onboarding.focus.Fitness"].tap()
        XCTAssertTrue(focusContinue.isEnabled)
        focusContinue.tap()

        // Starter habits
        let habitsContinue = app.buttons["onboarding.habitsContinue"]
        XCTAssertTrue(habitsContinue.waitForExistence(timeout: 3))
        habitsContinue.tap()

        // Reminders — turn off so the notification permission alert
        // doesn't appear during the test.
        let remindersToggle = app.switches["onboarding.remindersToggle"]
        XCTAssertTrue(remindersToggle.waitForExistence(timeout: 3))
        if remindersToggle.value as? String == "1" {
            tapSwitch(remindersToggle)
        }

        app.buttons["onboarding.finish"].tap()

        // Onboarding closes and a starter habit is in the habit list.
        XCTAssertTrue(
            app.staticTexts["onboarding.welcomeTitle"].waitForNonExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["Workout"].waitForExistence(timeout: 5))
    }

    func testSavingJournalEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-RippleUITestOpenJournal"]
        app.launch()

        let todayRow = app.buttons["journal.todayRow"]
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5))
        todayRow.tap()

        let editor = app.textViews["journal.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3))

        app.buttons["journal.mood.4"].tap()

        // Replace any text from an earlier run with a unique entry.
        let entryText = "UI test entry \(Int(Date().timeIntervalSince1970))"
        editor.tap()
        if let oldText = editor.value as? String, !oldText.isEmpty {
            editor.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldText.count))
        }
        editor.typeText(entryText)

        app.buttons["journal.save"].tap()

        // Back on the list, today's row shows the saved text. The row's
        // texts are merged into one button label, so match by label.
        let savedRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", entryText))
            .firstMatch
        XCTAssertTrue(savedRow.waitForExistence(timeout: 5))
    }

    // SwiftUI toggles sometimes ignore a tap on the whole row.
    private func tapSwitch(_ toggle: XCUIElement) {
        let before = toggle.value as? String
        toggle.tap()
        if toggle.value as? String == before {
            toggle.switches.firstMatch.tap()
        }
    }
}
