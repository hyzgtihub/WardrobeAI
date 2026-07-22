import XCTest

final class SmokeTests: XCTestCase {
    @MainActor
    func testRootShowsSignedOutState() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["auth.signInWithApple"].waitForExistence(timeout: 3))
    }
}
