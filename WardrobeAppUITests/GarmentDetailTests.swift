import XCTest

final class GarmentDetailTests: XCTestCase {
    @MainActor
    func testP05CardOpensEditableP09() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "wardrobe"]
        app.launch()

        let card = app.buttons["designSystem.garment.white-linen-shirt"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        XCTAssertTrue(app.staticTexts["garmentDetail.title"].waitForExistence(timeout: 3))
        for identifier in ["garmentDetail.back", "garmentDetail.more", "garmentDetail.changePhoto"] {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.exists, identifier)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44, identifier)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44, identifier)
        }
        XCTAssertTrue(app.buttons["garmentDetail.field.category"].exists)
        XCTAssertFalse(app.buttons["garmentDetail.save"].exists)
    }

    @MainActor
    func testAnyPersistedCardOpensItsOwnDetail() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "wardrobe"]
        app.launch()

        let card = app.buttons["designSystem.garment.beige-trench"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        let name = app.textFields["garmentDetail.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertEqual(name.value as? String, "米色风衣")
    }
}
