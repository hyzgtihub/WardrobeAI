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

    @MainActor
    func testCenterTabOpensPhotoPicker() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "wardrobe"]
        app.launch()

        app.buttons["designSystem.tab.addGarment"].tap()
        XCTAssertTrue(app.buttons["addGarment.choosePhoto"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCreatedGarmentAppearsAfterReturningFromDetail() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "add-garment", "-ui-add-garment-scenario", "success"]
        app.launch()

        app.buttons["addGarment.choosePhoto"].tap()
        app.buttons["addGarment.usePhoto"].tap()
        let name = app.textFields["addGarment.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText("新增衬衫")
        app.buttons["addGarment.category.tops"].tap()
        app.buttons["addGarment.season.spring"].tap()
        app.buttons["addGarment.submit"].tap()
        XCTAssertTrue(app.staticTexts["garmentDetail.title"].waitForExistence(timeout: 4))

        app.buttons["garmentDetail.back"].tap()
        let createdCard = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "新增衬衫")).firstMatch
        XCTAssertTrue(createdCard.waitForExistence(timeout: 3))
    }
}
