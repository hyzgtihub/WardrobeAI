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
        app.buttons["auth.signUp.requestCode"].tap()

        XCTAssertTrue(element("auth.signUp.email.error", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(email.value as? String, "mia@example.com")
    }

    @MainActor
    func testRegisteredEmailBlocksDetailsUntilEmailChanges() {
        let app = launch(scenario: "registration-failure")
        app.buttons["auth.register"].tap()

        enterSignUpCredentials(in: app)
        app.buttons["auth.signUp.requestCode"].tap()

        let email = app.textFields["auth.signUp.email"]
        let password = app.textFields["auth.signUp.password"]
        let confirmation = app.textFields["auth.signUp.confirmation"]
        let requestCode = app.buttons["auth.signUp.requestCode"]
        XCTAssertTrue(element("auth.signUp.email.error", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(email.isEnabled)
        XCTAssertFalse(password.isEnabled)
        XCTAssertFalse(confirmation.isEnabled)
        XCTAssertFalse(requestCode.isEnabled)

        email.tap()
        email.typeText("x")

        XCTAssertTrue(password.isEnabled)
        XCTAssertTrue(confirmation.isEnabled)
        XCTAssertTrue(requestCode.isEnabled)
    }

    @MainActor
    func testSignupCodeVerificationReachesWardrobe() {
        let app = launch(scenario: "registration-success")
        app.buttons["auth.register"].tap()

        enterSignUpCredentials(in: app)
        app.buttons["auth.signUp.requestCode"].tap()

        let code = app.textFields["auth.signUp.code"]
        XCTAssertTrue(code.waitForExistence(timeout: 3))
        code.tap()
        code.typeText("123456")
        app.buttons["auth.signUp.submit"].tap()

        XCTAssertTrue(app.staticTexts["wardrobe.title"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSuccessfulCodeRequestUsesEnumerationSafeMessage() {
        let app = launch(scenario: "registration-success")
        app.buttons["auth.register"].tap()

        enterSignUpCredentials(in: app)
        app.buttons["auth.signUp.requestCode"].tap()

        let message = element("auth.signUp.codeRequestNotice", in: app)
        XCTAssertTrue(message.waitForExistence(timeout: 3))
        XCTAssertEqual(
            message.label,
            "如果该邮箱尚未注册，验证码已发送；如果已经注册，请直接登录。"
        )
    }

    @MainActor
    func testSignupCodeFieldUsesConcisePromptWithoutChangeEmailButton() {
        let app = launch(scenario: "registration-success")
        app.buttons["auth.register"].tap()

        let code = app.textFields["auth.signUp.code"]
        XCTAssertTrue(code.waitForExistence(timeout: 3))
        XCTAssertEqual(code.placeholderValue, "请输入邮件验证码")
        XCTAssertFalse(app.buttons["auth.signUp.changeEmail"].exists)
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
    private func enterSignUpCredentials(in app: XCUIApplication) {
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
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
