import XCTest

final class WardrobeHomeTests: XCTestCase {
    @MainActor
    func testP05ControlsAndFilteringAreReachable() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "wardrobe"]
        app.launch()

        let identifiers = [
            "wardrobe.search",
            "designSystem.tab.addGarment",
            "designSystem.tab.profile"
        ]
        for identifier in identifiers {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.waitForExistence(timeout: 3), identifier)
            XCTAssertGreaterThanOrEqual(control.frame.width, 44, identifier)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44, identifier)
        }

        app.buttons["designSystem.category.tops"].tap()
        XCTAssertTrue(app.buttons["designSystem.garment.white-linen-shirt"].exists)
        XCTAssertFalse(app.buttons["designSystem.garment.beige-trench"].exists)
        app.buttons["designSystem.garment.white-linen-shirt"].tap()
    }
}
