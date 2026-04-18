import XCTest

final class LeaderboardUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
    }

    // MARK: - Period Picker

    /// Verifies that tapping each segment of the period picker updates the selection.
    /// Requires TEST_ACCOUNT_EMAIL and TEST_ACCOUNT_PASSWORD in Secrets.plist.
    func testLeaderboardPeriodPicker_switchesPeriod() throws {
        try loginWithTestAccount()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15),
                      "Tab bar should appear after login")
        app.tabBars.buttons["Leaderboard"].tap()

        // The period picker is the second segmented control (scope picker is first).
        // Buttons are addressed by index: 0=Week, 1=Month, 2=All Time.
        let picker = app.segmentedControls.element(boundBy: 1)
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Period picker should exist")

        let weekButton    = picker.buttons.element(boundBy: 0)
        let monthButton   = picker.buttons.element(boundBy: 1)
        let allTimeButton = picker.buttons.element(boundBy: 2)

        // Switch to Month
        monthButton.tap()
        XCTAssertTrue(monthButton.isSelected,    "Month should be selected after tap")
        XCTAssertFalse(weekButton.isSelected,    "Week should not be selected")
        XCTAssertFalse(allTimeButton.isSelected, "All Time should not be selected")

        // Switch to All Time
        allTimeButton.tap()
        XCTAssertTrue(allTimeButton.isSelected,  "All Time should be selected after tap")
        XCTAssertFalse(monthButton.isSelected,   "Month should not be selected")

        // Switch back to Week
        weekButton.tap()
        XCTAssertTrue(weekButton.isSelected, "Week should be selected after tap")
    }

    // MARK: - Helpers

    private func loginWithTestAccount() throws {
        let secrets = loadSecrets()
        guard
            let email    = secrets["TEST_ACCOUNT_EMAIL"],
            let password = secrets["TEST_ACCOUNT_PASSWORD"],
            !email.hasPrefix("REPLACE"),
            !password.hasPrefix("REPLACE")
        else {
            throw XCTSkip("Fill in TEST_ACCOUNT_EMAIL and TEST_ACCOUNT_PASSWORD in Secrets.plist to run this test.")
        }

        let emailField = app.textFields["emailField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["authButton"].tap()
    }

    private func loadSecrets() -> [String: String] {
        guard
            let path = Bundle(for: LeaderboardUITests.self).path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: String]
        else { return [:] }
        return dict
    }
}
