//
//  RippleUITests.swift
//  RippleUITests
//
//  Created by Brendon Young on 10/26/26.
//

import XCTest

final class RippleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = XCUIApplication()

        app.launch()

        // Verify that Ripple launches and displays its interface.
        XCTAssertTrue(app.waitForExistence(timeout: 10))
    }

    @MainActor
    func testAppCanLaunchMoreThanOnce() throws {
        let app = XCUIApplication()

        app.launch()

        XCTAssertTrue(app.waitForExistence(timeout: 10))

        app.terminate()
        app.launch()

        XCTAssertTrue(app.waitForExistence(timeout: 10))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
            app.terminate()
        }
    }
}
