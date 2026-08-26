import XCTest

final class SmokeTests: XCTestCase {
    @MainActor
    func testSuccessfulSignInOpensWardrobeHome() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-auth-scenario", "login-success"]
        app.launch()

        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 3))
        email.tap()
        email.typeText("mia@example.com")

        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("password")

        let signIn = app.buttons["auth.signIn"]
        XCTAssertTrue(signIn.isEnabled)
        signIn.tap()

        XCTAssertTrue(app.staticTexts["wardrobe.title"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["onboarding.retry"].exists)
    }

    @MainActor
    func testP01ReachesRegistration() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-auth-scenario", "signed-out"]
        app.launch()

        let register = app.buttons["auth.register"]
        XCTAssertTrue(register.waitForExistence(timeout: 3))
        register.tap()
        XCTAssertTrue(app.staticTexts["auth.signUp.title"].waitForExistence(timeout: 2))
    }
}
