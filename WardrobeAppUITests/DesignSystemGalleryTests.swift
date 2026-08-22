import XCTest

final class DesignSystemGalleryTests: XCTestCase {
    @MainActor
    func testCategoryAndBottomNavigationAreReachable() {
        let app = launchGallery()

        app.buttons["designSystem.category.tops"].tap()
        XCTAssertEqual(app.staticTexts["designSystem.selection.category"].label, "上衣")

        app.buttons["designSystem.tab.profile"].tap()
        XCTAssertEqual(app.staticTexts["designSystem.selection.tab"].label, "我的")
    }

    @MainActor
    func testDisabledAndLoadingButtonsDoNotSendActions() {
        let app = launchGallery()

        XCTAssertEqual(app.staticTexts["designSystem.actionCount"].label, "0")
        XCTAssertFalse(app.buttons["designSystem.button.disabled"].isEnabled)
        XCTAssertFalse(app.buttons["designSystem.button.loading"].isEnabled)
        XCTAssertEqual(app.staticTexts["designSystem.actionCount"].label, "0")
    }

    @MainActor
    func testAllIndependentControlsMeetMinimumTouchSize() {
        let app = launchGallery()
        let identifiers = [
            "designSystem.button.primary",
            "designSystem.button.disabled",
            "designSystem.button.loading",
            "designSystem.category.all",
            "designSystem.category.tops",
            "designSystem.tab.wardrobe",
            "designSystem.tab.addGarment",
            "designSystem.tab.profile"
        ]

        for identifier in identifiers {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.waitForExistence(timeout: 2), "Missing \(identifier)")
            XCTAssertGreaterThanOrEqual(control.frame.width, 44, identifier)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44, identifier)
        }
    }

    @MainActor
    private func launchGallery() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-design-system-gallery")
        app.launch()
        return app
    }
}
