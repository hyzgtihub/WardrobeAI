import XCTest

final class AuthSessionFlowTests: XCTestCase {
    @MainActor
    func testSuccessfulLoginReachesWardrobe() {
        let app = launch(scenario: "login-success")

        enterSignInCredentials(in: app)
        app.buttons["auth.signIn"].tap()

        XCTAssertTrue(app.staticTexts["wardrobe.title"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFailedLoginKeepsEnteredEmailAndShowsError() {
        let app = launch(scenario: "login-failure")

        enterSignInCredentials(in: app)
        app.buttons["auth.signIn"].tap()

        XCTAssertTrue(element("auth.error", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(app.textFields["auth.email"].value as? String, "mia@example.com")
    }

    @MainActor
    func testRegistrationFailureKeepsEnteredEmail() {
        let app = launch(scenario: "registration-failure")
        app.buttons["auth.register"].tap()

        let email = app.textFields["auth.signUp.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 3))
        email.tap()
        email.typeText("mia@example.com")
        app.buttons["auth.signUp.password"].tap()
        let password = app.textFields["auth.signUp.password"]
        password.tap()
        password.typeText("password")
        app.buttons["auth.signUp.confirmation"].tap()
        let confirmation = app.textFields["auth.signUp.confirmation"]
        confirmation.tap()
        confirmation.typeText("password")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        let submit = app.buttons["auth.signUp.submit"]
        XCTAssertTrue(submit.isEnabled)
        submit.tap()

        XCTAssertTrue(element("auth.error", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(email.value as? String, "mia@example.com")
    }

    @MainActor
    func testSignedInProfileCanSignOutToLogin() {
        let app = launch(scenario: "signed-in")

        let profileTab = app.buttons["designSystem.tab.profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 3))
        profileTab.tap()
        XCTAssertTrue(element("profile.screen", in: app).waitForExistence(timeout: 3))
        app.buttons["profile.signOut"].tap()

        XCTAssertTrue(app.buttons["auth.signIn"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func launch(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-auth-scenario", scenario]
        app.launch()
        return app
    }

    @MainActor
    private func enterSignInCredentials(in app: XCUIApplication) {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 3))
        email.tap()
        email.typeText("mia@example.com")
        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("password")
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
