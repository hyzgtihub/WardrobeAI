import XCTest

final class SmokeTests: XCTestCase {
    @MainActor
    func testP01ReachesRegistration() {
        let app = XCUIApplication()
        app.launch()

        let register = app.buttons["auth.register"]
        XCTAssertTrue(register.waitForExistence(timeout: 3))
        register.tap()
        XCTAssertTrue(app.staticTexts["auth.signUp.title"].waitForExistence(timeout: 2))
    }
}
