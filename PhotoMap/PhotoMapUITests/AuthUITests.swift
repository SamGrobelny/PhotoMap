import XCTest

final class AuthUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Forces LoginScreen to show even if a Supabase session is already cached on device.
        app.launchArguments = ["-uitesting"]
        app.launch()
    }

    // MARK: - Form Validation

    /// Verifies the login button is disabled until both email and password are filled.
    func testLoginFormValidation_buttonDisabledUntilFieldsFilled() throws {
        let authButton = app.buttons["authButton"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
        XCTAssertFalse(authButton.isEnabled, "Auth button should be disabled with empty fields")

        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.typeText("test@example.com")
        XCTAssertFalse(authButton.isEnabled, "Auth button should still be disabled with only email filled")

        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText("password123")
        XCTAssertTrue(authButton.isEnabled, "Auth button should be enabled once both fields are filled")
    }

    // MARK: - Combined Flow

    /// Full auth lifecycle:
    ///   1. Sign up a new account
    ///   2. Sign out via Profile → gear → "Sign Out"
    ///   3. Log back in with the same credentials
    /// The account is deleted via the Supabase Admin API in teardown.
    func testSignUpThenSignOutThenLogin() throws {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email     = "uitest+\(timestamp)@example.com"
        let username  = "uitest\(timestamp)"
        let password  = "Test@123"

        // Register cleanup before any actions so it runs even if the test fails midway.
        addTeardownBlock { [email, password] in
            await self.deleteTestAccount(email: email, password: password)
        }

        // MARK: Sign Up

        let toggleButton = app.buttons["toggleModeButton"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 5))
        toggleButton.tap()

        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.typeText(email)

        let usernameField = app.textFields["usernameField"]
        usernameField.tap()
        usernameField.typeText(username)
   
        XCTAssertTrue(app.images["checkmark.circle.fill"].waitForExistence(timeout: 10),
                      "Username availability check did not complete")

        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText(password)

        let authButton = app.buttons["authButton"]
        XCTAssertTrue(authButton.isEnabled, "Sign Up button should be enabled with valid inputs")
        authButton.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15),
                      "Tab bar should appear after successful sign up")

        // MARK: Sign Out

        app.tabBars.buttons["Profile"].tap()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()

        let confirmSignOut = app.alerts.firstMatch.buttons.matching(identifier: "confirmSignOutButton").firstMatch
        XCTAssertTrue(confirmSignOut.waitForExistence(timeout: 10))
        confirmSignOut.tap()

        XCTAssertTrue(app.textFields["emailField"].waitForExistence(timeout: 10),
                      "Login screen should reappear after sign out")

        // MARK: Log In

        let loginEmail = app.textFields["emailField"]
        loginEmail.tap()
        loginEmail.typeText(email)

        let loginPassword = app.secureTextFields["passwordField"]
        loginPassword.tap()
        loginPassword.typeText(password)

        let loginButton = app.buttons["authButton"]
        XCTAssertTrue(loginButton.isEnabled, "Login button should be enabled once fields are filled")
        loginButton.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15),
                      "Tab bar should appear after successful login")
    }

    // MARK: - Cleanup

    private func loadSecrets() -> [String: String] {
        guard
            let path = Bundle(for: AuthUITests.self).path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: String]
        else {
            return [:]
        }
        return dict
    }

    /// Calls the Supabase Admin API to delete the account created during a test run.
    private func deleteTestAccount(email: String, password: String) async {
        let secrets = loadSecrets()
        guard
            let supabaseURL    = secrets["SUPABASE_URL"],
            let serviceRoleKey = secrets["SUPABASE_SERVICE_ROLE_KEY"],
            !serviceRoleKey.hasPrefix("REPLACE")
        else {
            print("Skipping account deletion: fill in SUPABASE_SERVICE_ROLE_KEY in Secrets.plist.")
            return
        }

        do {
            // Step 1 — sign in to retrieve the user's UUID.
            let signInURL = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password")!
            var signInReq = URLRequest(url: signInURL)
            signInReq.httpMethod = "POST"
            signInReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            signInReq.setValue(serviceRoleKey, forHTTPHeaderField: "apikey")
            signInReq.httpBody = try JSONSerialization.data(withJSONObject: [
                "email": email,
                "password": password
            ])

            let (signInData, _) = try await URLSession.shared.data(for: signInReq)

            struct SignInResponse: Decodable {
                struct User: Decodable { let id: String }
                let user: User
            }
            let signIn = try JSONDecoder().decode(SignInResponse.self, from: signInData)

            // Step 2 — delete the user via the Admin API.
            let deleteURL = URL(string: "\(supabaseURL)/auth/v1/admin/users/\(signIn.user.id)")!
            var deleteReq = URLRequest(url: deleteURL)
            deleteReq.httpMethod = "DELETE"
            deleteReq.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
            deleteReq.setValue(serviceRoleKey, forHTTPHeaderField: "apikey")

            let (_, deleteResp) = try await URLSession.shared.data(for: deleteReq)

            if let http = deleteResp as? HTTPURLResponse, http.statusCode == 200 {
                print("Test account deleted: \(email)")
            } else {
                print("Admin delete returned unexpected status for \(email)")
            }
        } catch {
            print("Failed to delete test account '\(email)': \(error.localizedDescription)")
        }
    }
}
