import XCTest

final class AddGarmentFlowTests: XCTestCase {
    @MainActor
    func testPreviewSupportsReselectAndUsePhoto() {
        let app = launch(extraArguments: [
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ])

        let choose = app.buttons["addGarment.choosePhoto"]
        XCTAssertTrue(choose.waitForExistence(timeout: 3))
        assertMinimumTouchTarget(choose)
        choose.tap()

        XCTAssertTrue(app.images["addGarment.photoPreview"].waitForExistence(timeout: 3))
        assertMinimumTouchTarget(app.buttons["addGarment.reselectPhoto"])
        assertMinimumTouchTarget(app.buttons["addGarment.usePhoto"])

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["addGarment.usePhoto"].waitForExistence(timeout: 2))

        app.buttons["addGarment.reselectPhoto"].tap()
        XCTAssertTrue(choose.waitForExistence(timeout: 2))
        choose.tap()
        app.buttons["addGarment.usePhoto"].tap()
        XCTAssertTrue(app.textFields["addGarment.name"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRequiredErrorsFollowFormOrder() {
        let app = launchAtForm()
        let submit = app.buttons["addGarment.submit"]

        submit.tap()
        XCTAssertEqual(app.staticTexts["addGarment.error"].label, "请输入衣物名称")

        let name = app.textFields["addGarment.name"]
        name.tap()
        name.typeText("白衬衫")
        submit.tap()
        XCTAssertEqual(app.staticTexts["addGarment.error"].label, "请选择衣物分类")

        app.buttons["addGarment.category.tops"].tap()
        submit.tap()
        XCTAssertEqual(app.staticTexts["addGarment.error"].label, "请至少选择一个季节")
    }

    @MainActor
    func testFormReselectPreservesEnteredFields() {
        let app = launchAtForm()
        let name = app.textFields["addGarment.name"]
        name.tap()
        name.typeText("保留名称")

        let reselect = app.buttons["addGarment.reselectPhoto"]
        XCTAssertTrue(reselect.waitForExistence(timeout: 2))
        reselect.tap()
        XCTAssertTrue(app.buttons["addGarment.choosePhoto"].waitForExistence(timeout: 2))
        app.buttons["addGarment.choosePhoto"].tap()
        app.buttons["addGarment.usePhoto"].tap()

        XCTAssertEqual(app.textFields["addGarment.name"].value as? String, "保留名称")
    }

    @MainActor
    func testUploadFailurePreservesFieldsAndRetryOpensDetail() {
        let app = launchAtForm(scenario: "upload-failure")
        completeRequiredFields(in: app, name: "重试衬衫")

        let submit = app.buttons["addGarment.submit"]
        submit.tap()
        let error = app.staticTexts["addGarment.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "照片上传失败，请重试")
        XCTAssertEqual(app.textFields["addGarment.name"].value as? String, "重试衬衫")

        submit.tap()
        XCTAssertTrue(app.staticTexts["garmentDetail.title"].waitForExistence(timeout: 4))
    }

    @MainActor
    func testCreateFailurePreservesFieldsAndRetryOpensDetail() {
        let app = launchAtForm(scenario: "create-failure")
        completeRequiredFields(in: app, name: "补偿衬衫")

        let submit = app.buttons["addGarment.submit"]
        submit.tap()
        let error = app.staticTexts["addGarment.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "衣物保存失败，请重试")
        XCTAssertEqual(app.textFields["addGarment.name"].value as? String, "补偿衬衫")

        submit.tap()
        XCTAssertTrue(app.staticTexts["garmentDetail.title"].waitForExistence(timeout: 4))
    }

    @MainActor
    func testSubmittingDisablesDuplicateActionAndOpensDetail() {
        let app = launchAtForm()
        completeRequiredFields(in: app, name: "新衬衫")

        let submit = app.buttons["addGarment.submit"]
        submit.tap()
        XCTAssertFalse(submit.isEnabled)
        XCTAssertTrue(app.staticTexts["garmentDetail.title"].waitForExistence(timeout: 4))
    }

    @MainActor
    private func launchAtForm(scenario: String = "success") -> XCUIApplication {
        let app = launch(scenario: scenario)
        app.buttons["addGarment.choosePhoto"].tap()
        XCTAssertTrue(app.buttons["addGarment.usePhoto"].waitForExistence(timeout: 3))
        app.buttons["addGarment.usePhoto"].tap()
        XCTAssertTrue(app.textFields["addGarment.name"].waitForExistence(timeout: 2))
        return app
    }

    @MainActor
    private func launch(scenario: String = "success", extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-ui-screen", "add-garment",
            "-ui-add-garment-scenario", scenario,
        ]
        app.launchArguments += extraArguments
        app.launch()
        return app
    }

    @MainActor
    private func completeRequiredFields(in app: XCUIApplication, name: String) {
        let field = app.textFields["addGarment.name"]
        field.tap()
        field.typeText(name)
        app.buttons["addGarment.category.tops"].tap()
        app.buttons["addGarment.season.spring"].tap()
    }

    @MainActor
    private func assertMinimumTouchTarget(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let frame = element.frame
        XCTAssertGreaterThanOrEqual(frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.height, 44, file: file, line: line)
    }
}
