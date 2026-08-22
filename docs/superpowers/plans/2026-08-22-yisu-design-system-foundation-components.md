# YISU Design System Foundation & Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Execute inline with one primary agent; do not use routine subagent review.

**Goal:** Build the first production-ready YISU SwiftUI design-system batch: foundation tokens, Button, Content State, Category Chip/Filter, Garment Card/Grid, and Bottom Navigation.

**Architecture:** Keep the design system inside the existing `YISU` application target. Views consume immutable model values and report events through closures; pure state rules remain testable without third-party view-inspection libraries. A UI-test-only component gallery verifies accessibility reachability and interaction wiring.

**Tech Stack:** Swift 6, SwiftUI, iOS 17, Swift Testing, XCTest UI testing, XcodeGen project configuration.

**Spec:** `docs/superpowers/specs/2026-08-22-yisu-design-system-foundation-components-design.md`

## Global Constraints

- Support iOS 17 and Swift 6.
- Keep all code in the existing application and test targets; add no package dependency.
- Implement Light Mode only.
- Keep components independent of routing, networking, persistence, and concrete feature pages.
- Use semantic tokens; do not scatter raw colors through component files.
- Every independent action has a minimum `44×44pt` hit area and stable accessibility metadata.
- Use test-first Red → Green → Refactor for every production behavior.
- Preserve unrelated working-tree changes and do not modify the existing Apple sign-in placeholder flow outside the UI-test launch switch.

---

### Task 1: Foundation Tokens and Display Models

**Files:**
- Create: `WardrobeApp/DesignSystem/Foundation/YISUTheme.swift`
- Create: `WardrobeApp/DesignSystem/Models/YISUCategory.swift`
- Create: `WardrobeApp/DesignSystem/Models/GarmentSummary.swift`
- Create: `WardrobeApp/DesignSystem/Models/YISUComponentState.swift`
- Create: `WardrobeAppTests/DesignSystem/FoundationTests.swift`
- Create: `WardrobeAppTests/DesignSystem/ModelTests.swift`

**Interfaces:**
- Produces: `YISUTheme`, `YISUCategory.allCases`, `GarmentSummary`, `YISUControlState.isInteractive`, `YISUGarmentCardState`.
- Consumes: no Task-specific interfaces.

- [ ] **Step 1: Write failing foundation tests**

```swift
import SwiftUI
import Testing
@testable import YISU

struct FoundationTests {
    @Test func minimumTouchTargetIs44Points() {
        #expect(YISUTheme.Size.minimumTouchTarget == 44)
    }

    @Test func spacingUsesFourPointBaseGrid() {
        #expect(YISUTheme.Spacing.xs == 4)
        #expect(YISUTheme.Spacing.sm == 8)
        #expect(YISUTheme.Spacing.md == 16)
        #expect(YISUTheme.Spacing.lg == 24)
    }
}
```

- [ ] **Step 2: Run the new foundation tests and verify RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/FoundationTests
```

Expected: compilation fails because `YISUTheme` does not exist.

- [ ] **Step 3: Write failing model tests**

```swift
import Testing
@testable import YISU

struct ModelTests {
    @Test func categoryOrderMatchesGateB4() {
        #expect(YISUCategory.allCases.map(\.title) == [
            "全部", "上衣", "裤子", "外套", "裙子", "鞋子", "配饰", "其他"
        ])
    }

    @Test(arguments: [YISUControlState.disabled, .loading])
    func inactiveControlStatesRejectActions(_ state: YISUControlState) {
        #expect(state.isInteractive == false)
    }

    @Test func garmentSummaryKeepsPresentationDataOnly() {
        let item = GarmentSummary(id: "linen-shirt", title: "白色亚麻衬衫", metadata: "春夏 · 上衣", imageName: nil)
        #expect(item.title == "白色亚麻衬衫")
        #expect(item.imageName == nil)
    }
}
```

- [ ] **Step 4: Run the model tests and verify RED**

Run the same `xcodebuild test` command with `-only-testing:YISUTests/ModelTests`.

Expected: compilation fails because the model types do not exist.

- [ ] **Step 5: Implement the minimal foundation and models**

Implement semantic nested namespaces in `YISUTheme` (`Color`, `Typography`, `Spacing`, `Radius`, `Shadow`, `Size`), the eight-case `YISUCategory`, an `Identifiable/Equatable/Sendable` `GarmentSummary`, and these enums:

```swift
enum YISUControlState: Equatable, Sendable {
    case normal, pressed, disabled, loading
    var isInteractive: Bool { self != .disabled && self != .loading }
}

enum YISUGarmentCardState: Equatable, Sendable {
    case normal, pressed, loading, imageError
}
```

- [ ] **Step 6: Run Task 1 tests and verify GREEN**

Run both new test suites. Expected: all Task 1 tests pass with zero warnings introduced by the new files.

- [ ] **Step 7: Commit Task 1**

```bash
git add WardrobeApp/DesignSystem WardrobeAppTests/DesignSystem
git commit -m "feat: add YISU design foundation"
```

---

### Task 2: Button, Content State, and Category Controls

**Files:**
- Create: `WardrobeApp/DesignSystem/Components/YISUButton.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUContentStateView.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUCategoryChip.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUCategoryFilter.swift`
- Create: `WardrobeAppTests/DesignSystem/ControlBehaviorTests.swift`

**Interfaces:**
- Consumes: `YISUTheme`, `YISUCategory`, `YISUControlState`.
- Produces: `YISUButton`, `YISUContentStateView`, `YISUCategoryChip`, `YISUCategoryFilter`, `YISUContentState`.

- [ ] **Step 1: Write failing control-behavior tests**

```swift
import Testing
@testable import YISU

struct ControlBehaviorTests {
    @Test(arguments: [YISUControlState.disabled, .loading])
    func buttonPolicyBlocksInactiveStates(_ state: YISUControlState) {
        #expect(YISUButtonPolicy.canSendAction(in: state) == false)
    }

    @Test func buttonPolicyAllowsNormalState() {
        #expect(YISUButtonPolicy.canSendAction(in: .normal))
    }

    @Test func loadingContentHasNoAction() {
        #expect(YISUContentState.loading.allowsAction == false)
    }

    @Test func categorySelectionReturnsTappedCategory() {
        #expect(YISUCategorySelection.select(.tops, current: .all) == .tops)
    }
}
```

- [ ] **Step 2: Run the control tests and verify RED**

Expected: compilation fails because the policies and views do not exist.

- [ ] **Step 3: Implement minimal pure policies**

Add `YISUButtonPolicy.canSendAction(in:)`, `YISUContentState` with `allowsAction`, and `YISUCategorySelection.select(_:current:)` beside their owning components. Keep them internal and deterministic.

- [ ] **Step 4: Run policy tests and verify GREEN**

Expected: all `ControlBehaviorTests` pass.

- [ ] **Step 5: Implement the four SwiftUI views**

Required public initializers:

```swift
YISUButton(title:style:state:accessibilityIdentifier:action:)
YISUContentStateView(state:title:message:actionTitle:action:)
YISUCategoryChip(category:isSelected:action:)
YISUCategoryFilter(selection:onSelect:)
```

Use a custom `ButtonStyle` for pressed visuals. Guard the Button closure with `YISUButtonPolicy`; keep chip height at 44pt and filter horizontally scrollable. Add previews for normal and exceptional states.

- [ ] **Step 6: Build the application target**

Run:

```bash
xcodebuild build -project YISU.xcodeproj -scheme YISU -destination 'generic/platform=iOS Simulator'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Commit Task 2**

```bash
git add WardrobeApp/DesignSystem/Components WardrobeAppTests/DesignSystem/ControlBehaviorTests.swift
git commit -m "feat: add YISU shared controls"
```

---

### Task 3: Garment Card, Grid, and Bottom Navigation

**Files:**
- Create: `WardrobeApp/DesignSystem/Components/YISUGarmentCard.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUGarmentGrid.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUBottomNavigation.swift`
- Create: `WardrobeAppTests/DesignSystem/CollectionBehaviorTests.swift`

**Interfaces:**
- Consumes: `YISUTheme`, `GarmentSummary`, `YISUGarmentCardState`.
- Produces: `YISUGarmentCard`, `YISUGarmentGrid`, `YISUBottomNavigation`, `YISUTab`.

- [ ] **Step 1: Write failing collection-behavior tests**

```swift
import Testing
@testable import YISU

struct CollectionBehaviorTests {
    @Test func loadingCardCannotOpenGarment() {
        #expect(YISUGarmentCardPolicy.canOpen(state: .loading) == false)
    }

    @Test func normalCardCanOpenGarment() {
        #expect(YISUGarmentCardPolicy.canOpen(state: .normal))
    }

    @Test func bottomNavigationHasThreeOrderedTabs() {
        #expect(YISUTab.allCases == [.wardrobe, .addGarment, .profile])
    }
}
```

- [ ] **Step 2: Run collection tests and verify RED**

Expected: compilation fails because the card policy and tab enum do not exist.

- [ ] **Step 3: Implement the minimal policies and tab model**

Implement `YISUGarmentCardPolicy.canOpen(state:)` and a three-case `YISUTab: CaseIterable` with Chinese title, SF Symbol name, and stable accessibility identifier.

- [ ] **Step 4: Run collection tests and verify GREEN**

Expected: all `CollectionBehaviorTests` pass.

- [ ] **Step 5: Implement garment and navigation views**

Required public initializers:

```swift
YISUGarmentCard(item:state:onSelect:)
YISUGarmentGrid(items:stateForItem:onSelect:)
YISUBottomNavigation(selection:onSelect:)
```

Use `LazyVGrid` with two flexible columns. Keep card geometry stable across image-error/loading states, title at two lines with tail truncation, and metadata at one line. Bottom Navigation reports a tab and never owns routing.

- [ ] **Step 6: Run Task 1–3 unit tests and build**

Run all `YISUTests`, then the generic simulator build. Expected: all unit tests pass and build succeeds.

- [ ] **Step 7: Commit Task 3**

```bash
git add WardrobeApp/DesignSystem WardrobeAppTests/DesignSystem
git commit -m "feat: add garment and navigation components"
```

---

### Task 4: UI-Test Gallery and Full Verification

**Files:**
- Create: `WardrobeApp/DesignSystem/Preview/DesignSystemGalleryView.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Create: `WardrobeAppUITests/DesignSystemGalleryTests.swift`

**Interfaces:**
- Consumes: every component produced by Tasks 1–3.
- Produces: UI-test-only launch path `-design-system-gallery` and accessibility-backed interaction verification.

- [ ] **Step 1: Write failing UI tests**

```swift
import XCTest

final class DesignSystemGalleryTests: XCTestCase {
    @MainActor func testCategoryAndBottomNavigationAreReachable() {
        let app = XCUIApplication()
        app.launchArguments.append("-design-system-gallery")
        app.launch()

        app.buttons["designSystem.category.tops"].tap()
        XCTAssertEqual(app.staticTexts["designSystem.selection.category"].label, "上衣")

        app.buttons["designSystem.tab.profile"].tap()
        XCTAssertEqual(app.staticTexts["designSystem.selection.tab"].label, "我的")
    }

    @MainActor func testDisabledAndLoadingButtonsDoNotSendActions() {
        let app = XCUIApplication()
        app.launchArguments.append("-design-system-gallery")
        app.launch()

        XCTAssertEqual(app.staticTexts["designSystem.actionCount"].label, "0")
        XCTAssertFalse(app.buttons["designSystem.button.disabled"].isEnabled)
        XCTAssertFalse(app.buttons["designSystem.button.loading"].isEnabled)
    }
}
```

- [ ] **Step 2: Run the new UI test and verify RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUUITests/DesignSystemGalleryTests
```

Expected: tests fail because the gallery launch path and identifiers do not exist.

- [ ] **Step 3: Implement the UI-test-only gallery**

Create a scrollable gallery using every component. Store category, tab, and action-count state locally. In `RootView`, switch to the gallery only when `ProcessInfo.processInfo.arguments.contains("-design-system-gallery")`; retain `SignInView` for ordinary launches.

- [ ] **Step 4: Run the gallery UI tests and verify GREEN**

Expected: both gallery UI tests pass.

- [ ] **Step 5: Run full verification**

Run:

```bash
xcodebuild build -project YISU.xcodeproj -scheme YISU -destination 'generic/platform=iOS Simulator'
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `BUILD SUCCEEDED`, all unit/UI tests pass, and the pre-existing signed-out smoke test still finds `auth.signInWithApple` during a normal launch.

- [ ] **Step 6: Audit requirements and diff**

Check that every component initializer matches this plan, no component imports persistence/networking frameworks, no independent control frame is below 44pt, and `git diff --check` reports no whitespace errors.

- [ ] **Step 7: Commit Task 4**

```bash
git add WardrobeApp/App/RootView.swift WardrobeApp/DesignSystem/Preview WardrobeAppUITests/DesignSystemGalleryTests.swift
git commit -m "test: verify YISU design system gallery"
```

## Final Acceptance

- Foundation values and all model/state tests pass.
- Seven requested component families compile and render through the gallery.
- Category and bottom-navigation actions are reachable in UI tests.
- Disabled and Loading buttons cannot emit actions.
- Normal app launch still shows the existing signed-out state.
- Full build and test suite pass with no new warnings.
