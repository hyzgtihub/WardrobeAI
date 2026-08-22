import XCTest

final class OnboardingFlowTests: XCTestCase {
    @MainActor
    func testCreationFailureRetryIsReachable() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "onboarding", "-ui-state", "creationFailed"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.retry"].waitForExistence(timeout: 3))
    }
}
