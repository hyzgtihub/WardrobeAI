import XCTest

final class WardrobeHomeTests: XCTestCase {
    private let whiteShirt = "designSystem.garment.white-linen-shirt"
    private let blueKnit = "designSystem.garment.powder-blue-knit"
    private let beigeTrench = "designSystem.garment.beige-trench"
    private let blackDress = "designSystem.garment.black-knit-dress"

    @MainActor
    func testP05ControlsAndFilteringAreReachable() {
        let app = launchWardrobe()

        XCTAssertFalse(app.buttons["wardrobe.search"].exists)

        let filter = app.buttons["wardrobe.filter.open"]
        XCTAssertTrue(filter.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(filter.frame.width, 44)
        XCTAssertGreaterThanOrEqual(filter.frame.height, 44)

        for identifier in ["designSystem.tab.addGarment", "designSystem.tab.profile"] {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.waitForExistence(timeout: 3), identifier)
            XCTAssertGreaterThanOrEqual(control.frame.width, 44, identifier)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44, identifier)
        }

        app.buttons["wardrobe.category.tops"].tap()
        assertVisibleGarments([whiteShirt, blueKnit], in: app)
        assertHiddenGarments([beigeTrench, blackDress], in: app)
        app.buttons[whiteShirt].tap()
    }

    @MainActor
    func testClosingFilterDiscardsSeasonDraft() {
        let app = launchWardrobe()

        openFilter(in: app)
        selectFilterOption(dimension: "season", value: "春季", in: app)
        app.buttons["wardrobe.filter.close"].tap()
        waitForFilterToClose(in: app)

        XCTAssertFalse(app.buttons["wardrobe.filterChip.春季"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertAllGarmentsVisible(in: app)
    }

    @MainActor
    func testCompletingFilterAppliesSeasonAndShowsChipAndDot() {
        let app = launchWardrobe()

        applySeason("春季", in: app)

        XCTAssertTrue(app.buttons["wardrobe.filterChip.春季"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.active"].waitForExistence(timeout: 2))
        assertVisibleGarments([whiteShirt, blueKnit], in: app)
        assertHiddenGarments([beigeTrench, blackDress], in: app)
    }

    @MainActor
    func testResetThenClosePreservesAppliedFilter() {
        let app = launchWardrobe()
        applySeason("春季", in: app)

        openFilter(in: app)
        app.buttons["wardrobe.filter.reset"].tap()
        app.buttons["wardrobe.filter.close"].tap()
        waitForFilterToClose(in: app)

        XCTAssertTrue(app.buttons["wardrobe.filterChip.春季"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertVisibleGarments([whiteShirt, blueKnit], in: app)
        assertHiddenGarments([beigeTrench, blackDress], in: app)
    }

    @MainActor
    func testResetThenCompleteClearsAppliedFilter() {
        let app = launchWardrobe()
        applySeason("春季", in: app)

        openFilter(in: app)
        app.buttons["wardrobe.filter.reset"].tap()
        app.buttons["wardrobe.filter.apply"].tap()
        waitForFilterToClose(in: app)

        XCTAssertFalse(app.buttons["wardrobe.filterChip.春季"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertAllGarmentsVisible(in: app)
    }

    @MainActor
    func testSingleCategoryFiltersWithoutShowingNonCategoryDot() {
        let app = launchWardrobe()

        let outerwear = app.buttons["wardrobe.category.outerwear"]
        outerwear.tap()

        XCTAssertTrue(outerwear.isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertVisibleGarments([beigeTrench], in: app)
        assertHiddenGarments([whiteShirt, blueKnit, blackDress], in: app)
    }

    @MainActor
    func testCategoryAndSeasonFilterPreserveBothConditions() {
        let app = launchWardrobe()

        let tops = app.buttons["wardrobe.category.tops"]
        tops.tap()
        applySeason("秋季", in: app)

        XCTAssertTrue(tops.isSelected)
        XCTAssertTrue(app.buttons["wardrobe.filterChip.秋季"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertVisibleGarments([blueKnit], in: app)
        assertHiddenGarments([whiteShirt, beigeTrench, blackDress], in: app)
    }

    @MainActor
    func testMultipleCategoriesShowAggregateAndTappingCategoryReplacesSelection() {
        let app = launchWardrobe()

        openFilter(in: app)
        selectFilterOption(dimension: "category", value: "上衣", in: app)
        selectFilterOption(dimension: "category", value: "外套", in: app)
        app.buttons["wardrobe.filter.apply"].tap()
        waitForFilterToClose(in: app)

        let multiple = app.buttons["wardrobe.category.multiple"]
        XCTAssertTrue(multiple.waitForExistence(timeout: 2))
        XCTAssertTrue(multiple.isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertVisibleGarments([whiteShirt, blueKnit, beigeTrench], in: app)
        assertHiddenGarments([blackDress], in: app)

        app.buttons["wardrobe.category.dresses"].tap()

        XCTAssertTrue(multiple.waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.buttons["wardrobe.category.dresses"].isSelected)
        assertVisibleGarments([blackDress], in: app)
        assertHiddenGarments([whiteShirt, blueKnit, beigeTrench], in: app)
    }

    @MainActor
    func testCompoundDynamicFiltersUseCustomFixtureValues() {
        let app = launchWardrobe()

        openFilter(in: app)
        selectFilterOption(dimension: "material", value: "亚麻", in: app)
        selectFilterOption(dimension: "style", value: "通勤", in: app)
        selectFilterOption(dimension: "storageLocation", value: "主卧衣柜", in: app)
        app.buttons["wardrobe.filter.apply"].tap()
        waitForFilterToClose(in: app)

        XCTAssertTrue(app.buttons["wardrobe.filterChip.亚麻"].exists)
        XCTAssertTrue(app.buttons["wardrobe.filterChip.通勤"].exists)
        XCTAssertTrue(app.buttons["wardrobe.filterChip.主卧衣柜"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertVisibleGarments([whiteShirt], in: app)
        assertHiddenGarments([blueKnit, beigeTrench, blackDress], in: app)
    }

    @MainActor
    func testRemovingOneAppliedChipKeepsOtherCondition() {
        let app = launchWardrobe()

        openFilter(in: app)
        selectFilterOption(dimension: "season", value: "春季", in: app)
        selectFilterOption(dimension: "season", value: "秋季", in: app)
        app.buttons["wardrobe.filter.apply"].tap()
        waitForFilterToClose(in: app)

        app.buttons["wardrobe.filterChip.春季"].tap()

        XCTAssertFalse(app.buttons["wardrobe.filterChip.春季"].exists)
        XCTAssertTrue(app.buttons["wardrobe.filterChip.秋季"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertVisibleGarments([blueKnit, beigeTrench, blackDress], in: app)
        assertHiddenGarments([whiteShirt], in: app)
    }

    @MainActor
    func testNoResultsClearActionRestoresAllGarments() {
        let app = launchWardrobe()
        createNoResultsState(in: app)

        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filteredEmpty"].waitForExistence(timeout: 2))
        let clear = app.buttons["wardrobe.filter.clearAll"]
        XCTAssertTrue(clear.exists)
        XCTAssertTrue(app.buttons["wardrobe.filteredEmpty.add"].exists)
        clear.tap()

        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filteredEmpty"].waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.buttons["wardrobe.category.all"].isSelected)
        XCTAssertFalse(app.buttons["wardrobe.filterChip.春季"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["wardrobe.filter.active"].exists)
        assertAllGarmentsVisible(in: app)
    }

    @MainActor
    func testNoResultsAddActionOpensAddGarmentFlow() {
        let app = launchWardrobe()
        createNoResultsState(in: app)

        let add = app.buttons["wardrobe.filteredEmpty.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["wardrobe.filter.clearAll"].exists)
        add.tap()

        XCTAssertTrue(app.buttons["addGarment.choosePhoto"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCenterTabOpensPhotoPicker() {
        let app = launchWardrobe()

        app.buttons["designSystem.tab.addGarment"].tap()
        XCTAssertTrue(app.buttons["addGarment.choosePhoto"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCreatedGarmentAppearsAfterReturningFromDetail() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "add-garment", "-ui-add-garment-scenario", "success"]
        app.launch()

        let choosePhoto = app.buttons["addGarment.choosePhoto"]
        XCTAssertTrue(choosePhoto.waitForExistence(timeout: 3))
        choosePhoto.tap()
        let usePhoto = app.buttons["addGarment.usePhoto"]
        XCTAssertTrue(usePhoto.waitForExistence(timeout: 3))
        usePhoto.tap()
        let name = app.textFields["addGarment.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText("新增衬衫")
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            let returnKey = keyboard.buttons["Return"]
            XCTAssertTrue(returnKey.exists)
            returnKey.tap()
            XCTAssertTrue(keyboard.waitForNonExistence(timeout: 2))
        }
        app.buttons["addGarment.category"].tap()
        let tops = app.descendants(matching: .any)["picker.category.上衣"]
        XCTAssertTrue(tops.waitForExistence(timeout: 3))
        tops.tap()
        XCTAssertTrue(tops.waitForNonExistence(timeout: 2))
        app.buttons["addGarment.seasons"].tap()
        let spring = app.descendants(matching: .any)["picker.seasons.春季"]
        XCTAssertTrue(spring.waitForExistence(timeout: 3))
        spring.tap()
        let complete = app.buttons["picker.seasons.complete"]
        complete.tap()
        XCTAssertTrue(complete.waitForNonExistence(timeout: 2))
        app.buttons["addGarment.submit"].tap()
        XCTAssertTrue(app.textFields["garmentDetail.name"].waitForExistence(timeout: 4))

        app.buttons["garmentDetail.back"].tap()
        let createdCard = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "新增衬衫")).firstMatch
        XCTAssertTrue(createdCard.waitForExistence(timeout: 3))
    }

    @MainActor
    private func launchWardrobe() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-screen", "wardrobe"]
        app.launch()
        XCTAssertTrue(app.buttons["wardrobe.filter.open"].waitForExistence(timeout: 3))
        return app
    }

    @MainActor
    private func openFilter(in app: XCUIApplication) {
        app.buttons["wardrobe.filter.open"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.sheet"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func selectFilterOption(dimension: String, value: String, in app: XCUIApplication) {
        let option = app.buttons["wardrobe.filter.option.\(dimension).\(value)"]
        if !option.exists {
            let section = app.buttons["wardrobe.filter.dimension.\(dimension)"]
            XCTAssertTrue(section.waitForExistence(timeout: 2), dimension)
            makeHittable(section, in: app)
            section.tap()
        }
        XCTAssertTrue(option.waitForExistence(timeout: 2), "\(dimension): \(value)")
        makeHittable(option, in: app)
        option.tap()
    }

    @MainActor
    private func makeHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, element.identifier)
    }

    @MainActor
    private func applySeason(_ season: String, in app: XCUIApplication) {
        openFilter(in: app)
        selectFilterOption(dimension: "season", value: season, in: app)
        app.buttons["wardrobe.filter.apply"].tap()
        waitForFilterToClose(in: app)
    }

    @MainActor
    private func createNoResultsState(in app: XCUIApplication) {
        app.buttons["wardrobe.category.outerwear"].tap()
        applySeason("春季", in: app)
    }

    @MainActor
    private func waitForFilterToClose(in app: XCUIApplication) {
        XCTAssertTrue(app.descendants(matching: .any)["wardrobe.filter.sheet"].waitForNonExistence(timeout: 3))
    }

    @MainActor
    private func assertAllGarmentsVisible(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        assertVisibleGarments([whiteShirt, blueKnit, beigeTrench, blackDress], in: app, file: file, line: line)
    }

    @MainActor
    private func assertVisibleGarments(
        _ identifiers: [String],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for identifier in identifiers {
            XCTAssertTrue(app.buttons[identifier].waitForExistence(timeout: 2), identifier, file: file, line: line)
        }
    }

    @MainActor
    private func assertHiddenGarments(
        _ identifiers: [String],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for identifier in identifiers {
            XCTAssertTrue(app.buttons[identifier].waitForNonExistence(timeout: 2), identifier, file: file, line: line)
        }
    }
}
