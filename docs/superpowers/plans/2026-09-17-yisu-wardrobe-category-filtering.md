# YISU Wardrobe Category Filtering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace wardrobe text-search entry points with category browsing and an accessible, session-scoped multi-dimensional filter sheet over the locally loaded garments.

**Architecture:** `RootView` owns the applied `WardrobeFilter` for the signed-in session. Pure `WardrobeFilterPolicy` functions derive options, counts, and filtered garments; `WardrobeHomeView` composes a filter bar, counted category browser, and draft-only sheet without issuing new repository requests.

**Tech Stack:** Swift 6, SwiftUI, Observation, Swift Testing, XCTest UI tests, XcodeGen, iOS 17+

**Spec:** `docs/superpowers/specs/2026-09-17-yisu-wardrobe-category-filtering-design.md`

## Global Constraints

- iOS deployment target remains `17.0`; Swift remains `6.0`.
- Do not add dependencies, database migrations, remote queries, text search, favorites, or smart collections.
- Filter only `GarmentStore.garments` in memory and preserve their current order.
- Touch targets are at least `44×44 pt`; state is not communicated by color alone.
- Draft changes apply only through “完成”; close, swipe-dismiss, and system dismiss cancel them.
- Applied filters survive detail/add navigation but reset on sign-out, account change, or process restart.
- Generate the Xcode project from `project.yml`; do not treat generated project-file changes as the source of truth.

---

## File Structure

- Create `WardrobeApp/Features/Wardrobe/WardrobeFilter.swift`: filter value type, normalized option type, and filtering/option/count policy.
- Create `WardrobeApp/Features/Wardrobe/WardrobeFilterBar.swift`: filter trigger, status indicator, and removable applied-value chips.
- Create `WardrobeApp/Features/Wardrobe/WardrobeCategoryBrowser.swift`: counted categories and the multi-category aggregate state.
- Create `WardrobeApp/Features/Wardrobe/WardrobeFilterSheet.swift`: draft editor, expandable dimensions, reset/apply actions.
- Modify `WardrobeApp/Features/Wardrobe/WardrobeHomeView.swift`: integrate filtering UI and filtered/empty content.
- Modify `WardrobeApp/App/RootView.swift`: own and reset the session filter, pass full garments and a binding to home.
- Modify `WardrobeApp/DesignSystem/Models/YISUCategory.swift`: expose browseable categories without treating `.all` as a data value.
- Modify `WardrobeApp/DesignSystem/Components/YISUCategoryFilter.swift`: keep gallery compatibility or delegate to the new browser without duplicating product behavior.
- Create `WardrobeAppTests/Wardrobe/WardrobeFilterPolicyTests.swift`: normalization, option derivation, counts, OR/AND matching, and ordering.
- Modify `WardrobeAppTests/Wardrobe/WardrobeHomePolicyTests.swift`: replace legacy category-only expectations with compatibility coverage if the old policy remains.
- Modify `WardrobeAppUITests/WardrobeHomeTests.swift`: assert removed search, sheet draft/apply/cancel/reset, chips, indicator, category replacement, and empty state.

---

### Task 1: Define the filter domain and pure matching policy

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/WardrobeFilter.swift`
- Modify: `WardrobeApp/DesignSystem/Models/YISUCategory.swift`
- Create: `WardrobeAppTests/Wardrobe/WardrobeFilterPolicyTests.swift`

**Interfaces:**
- Produces: `struct WardrobeFilter: Equatable, Sendable`
- Produces: `struct WardrobeFilterOption: Identifiable, Equatable, Sendable`
- Produces: `enum WardrobeFilterDimension: CaseIterable, Identifiable, Sendable`
- Produces: `enum WardrobeFilterPolicy` with `filteredGarments`, `options`, `categoryCounts`, and normalization helpers.

- [ ] **Step 1: Write failing construction and derived-state tests**

Add tests proving the empty filter has no restrictions, non-category count excludes categories, and `YISUCategory.browseableCases` has the exact accepted order:

```swift
@Test func emptyFilterHasNoActiveConditions() {
    let filter = WardrobeFilter()
    #expect(filter.isEmpty)
    #expect(filter.hasNonCategoryConditions == false)
    #expect(filter.activeNonCategoryCount == 0)
}

@Test func browseableCategoryOrderIsFrozen() {
    #expect(YISUCategory.browseableCases == [
        .tops, .pants, .dresses, .outerwear, .shoes, .bags, .accessories, .other
    ])
}
```

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
xcodegen generate
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/WardrobeFilterPolicyTests CODE_SIGNING_ALLOWED=NO
```

Expected: compilation fails because `WardrobeFilter` and `browseableCases` do not exist.

- [ ] **Step 3: Implement the filter value and dimensions**

Create the exact filter contract:

```swift
struct WardrobeFilter: Equatable, Sendable {
    var categories: Set<YISUCategory> = []
    var seasons: Set<String> = []
    var colors: Set<String> = []
    var materials: Set<String> = []
    var styles: Set<String> = []
    var sizes: Set<String> = []
    var storageLocations: Set<String> = []

    var hasNonCategoryConditions: Bool {
        !seasons.isEmpty || !colors.isEmpty || !materials.isEmpty ||
        !styles.isEmpty || !sizes.isEmpty || !storageLocations.isEmpty
    }

    var activeNonCategoryCount: Int {
        [seasons, colors, materials, styles, sizes, storageLocations]
            .reduce(0) { $0 + $1.count }
    }

    var isEmpty: Bool { categories.isEmpty && !hasNonCategoryConditions }
}

enum WardrobeFilterDimension: String, CaseIterable, Identifiable, Sendable {
    case category, season, color, material, style, size, storageLocation
    var id: Self { self }
}

struct WardrobeFilterOption: Identifiable, Equatable, Sendable {
    let value: String
    let count: Int
    var id: String { value }
}
```

Add `YISUCategory.browseableCases` excluding `.all`; keep `allCases` compatibility for existing design-system previews until Task 4 migrates product usage.

- [ ] **Step 4: Write failing policy tests for every matching rule**

Use fixture garments covering mixed case and whitespace, array intersections, missing scalar values, custom values, and multiple categories. Assert:

```swift
@Test func sameDimensionUsesOrAndDifferentDimensionsUseAnd() {
    var filter = WardrobeFilter()
    filter.colors = ["白色", "黑色"]
    filter.seasons = ["春季"]
    let result = WardrobeFilterPolicy.filteredGarments(fixtures, by: filter)
    #expect(result.map(\.name) == ["白衬衫", "黑色春季外套"])
}

@Test func normalizationTrimsAndIgnoresEnglishCase() {
    #expect(WardrobeFilterPolicy.normalized("  Cotton ") ==
            WardrobeFilterPolicy.normalized("cotton"))
}
```

Also test that filtering preserves fixture order and an empty dimension imposes no restriction.

- [ ] **Step 5: Implement minimal pure filtering**

Implement `filteredGarments(_:by:)` with helper functions for array intersection and optional scalar matching. Compare only normalized values; never mutate garments. Category matching uses the enum values directly.

- [ ] **Step 6: Write failing dynamic-option and count tests**

Assert fixed season order, dynamic trim/case de-duplication, first stable display spelling, omission of empty values, custom values, category counts, and option counts from the complete fixture list.

- [ ] **Step 7: Implement option and count derivation**

Expose:

```swift
static func options(for dimension: WardrobeFilterDimension, in garments: [Garment]) -> [WardrobeFilterOption]
static func categoryCounts(in garments: [Garment]) -> [YISUCategory: Int]
static func normalized(_ value: String) -> String
```

Fixed seasons follow `GarmentFieldOptions.seasons`. Dynamic values retain the first stable display form and sort with `localizedStandardCompare`; counts use normalized equivalence.

- [ ] **Step 8: Run focused tests and commit**

Run the focused command from Step 2. Expected: all `WardrobeFilterPolicyTests` pass.

```bash
git add WardrobeApp/Features/Wardrobe/WardrobeFilter.swift WardrobeApp/DesignSystem/Models/YISUCategory.swift WardrobeAppTests/Wardrobe/WardrobeFilterPolicyTests.swift
git commit -m "feat: add wardrobe filtering policy"
```

---

### Task 2: Build the counted category browser

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/WardrobeCategoryBrowser.swift`
- Modify: `WardrobeApp/DesignSystem/Components/YISUCategoryFilter.swift`
- Modify: `WardrobeAppTests/DesignSystem/CollectionBehaviorTests.swift`

**Interfaces:**
- Consumes: `WardrobeFilter.categories`, `YISUCategory.browseableCases`, `WardrobeFilterPolicy.categoryCounts(in:)`.
- Produces: `WardrobeCategoryBrowser(categories:counts:onSelect:)` where selection is `Set<YISUCategory>` and `onSelect` returns a replacement set.

- [ ] **Step 1: Write failing selection-policy tests**

Add pure expectations for the browser rule:

```swift
@Test func selectingSingleCategoryReplacesMultipleSelection() {
    #expect(WardrobeCategorySelection.replacing([.tops, .pants], with: .dresses) == [.dresses])
}

@Test func selectingAllClearsCategoryRestriction() {
    #expect(WardrobeCategorySelection.replacing([.tops], with: nil).isEmpty)
}
```

- [ ] **Step 2: Verify the tests fail**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/CollectionBehaviorTests CODE_SIGNING_ALLOWED=NO
```

Expected: compilation fails because `WardrobeCategorySelection.replacing` does not exist.

- [ ] **Step 3: Implement the browser and compatibility wrapper**

Build a horizontal SwiftUI control with “全部”, the eight browseable categories, counts, and a synthetic “多分类” item only when `categories.count > 1`. Each control has a `44 pt` minimum height, selected trait, and stable identifiers:

```text
wardrobe.category.all
wardrobe.category.tops
wardrobe.category.multiple
```

Keep `YISUCategoryFilter` functional for the design-system gallery by delegating single-selection behavior or retaining its existing API; do not make `.all` a persisted category.

- [ ] **Step 4: Run design-system tests and commit**

Run the Step 2 command. Expected: pass.

```bash
git add WardrobeApp/Features/Wardrobe/WardrobeCategoryBrowser.swift WardrobeApp/DesignSystem/Components/YISUCategoryFilter.swift WardrobeAppTests/DesignSystem/CollectionBehaviorTests.swift
git commit -m "feat: add counted category browser"
```

---

### Task 3: Build applied-filter controls and draft sheet

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/WardrobeFilterBar.swift`
- Create: `WardrobeApp/Features/Wardrobe/WardrobeFilterSheet.swift`
- Create: `WardrobeAppTests/Wardrobe/WardrobeFilterDraftTests.swift`

**Interfaces:**
- Consumes: `WardrobeFilter`, `WardrobeFilterDimension`, and `WardrobeFilterPolicy.options(for:in:)`.
- Produces: `WardrobeFilterBar(filter:onOpen:onRemove:)`.
- Produces: `WardrobeFilterSheet(appliedFilter:garments:onApply:onCancel:)`.
- Produces: `struct WardrobeFilterDraft: Equatable` with `reset()`, `toggle(_:in:)`, and `filter`.

- [ ] **Step 1: Write failing draft transaction tests**

Prove initialization copies the applied filter, toggles are isolated, reset clears only the draft, and converting the draft yields the expected filter:

```swift
@Test func resettingDraftDoesNotMutateAppliedValue() {
    let applied = WardrobeFilter(seasons: ["春季"])
    var draft = WardrobeFilterDraft(applied)
    draft.reset()
    #expect(draft.filter.isEmpty)
    #expect(applied.seasons == ["春季"])
}
```

- [ ] **Step 2: Verify draft tests fail**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/WardrobeFilterDraftTests CODE_SIGNING_ALLOWED=NO
```

Expected: compilation fails because `WardrobeFilterDraft` does not exist.

- [ ] **Step 3: Implement draft state and the applied-filter bar**

Render a `44×44 pt` native filter button with the system filter icon. Show a brand-token dot only when `filter.hasNonCategoryConditions`; add accessibility value “已有条件” or “无附加条件”. Render each non-category value as a removable horizontal chip with accessibility label `移除筛选，<value>` and identifiers `wardrobe.filterChip.<normalized-value>`.

- [ ] **Step 4: Implement the filter sheet**

Use `.presentationDetents([.large])`, `.presentationDragIndicator(.visible)`, a scrollable set of disclosure sections, and a safe-area bottom action bar. Fixed category/season options and dynamic options display counts. Use `@State private var draft`, call `onApply(draft.filter)` only from “完成”, and call `onCancel` from explicit close. Parent dismissal handling must never copy draft into applied state.

Required identifiers:

```text
wardrobe.filter.open
wardrobe.filter.active
wardrobe.filter.sheet
wardrobe.filter.close
wardrobe.filter.reset
wardrobe.filter.apply
wardrobe.filter.dimension.<dimension>
wardrobe.filter.option.<dimension>.<normalized-value>
```

- [ ] **Step 5: Run draft tests and commit**

Run the Step 2 command. Expected: pass.

```bash
git add WardrobeApp/Features/Wardrobe/WardrobeFilterBar.swift WardrobeApp/Features/Wardrobe/WardrobeFilterSheet.swift WardrobeAppTests/Wardrobe/WardrobeFilterDraftTests.swift
git commit -m "feat: add wardrobe filter sheet"
```

---

### Task 4: Integrate filtering into the wardrobe home and session

**Files:**
- Modify: `WardrobeApp/Features/Wardrobe/WardrobeHomeView.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Modify: `WardrobeAppTests/Wardrobe/WardrobeHomePolicyTests.swift`

**Interfaces:**
- Consumes: all Task 1–3 interfaces.
- Changes: `WardrobeHomeView` accepts `garments: [Garment]` and `filter: Binding<WardrobeFilter>`.
- Produces: session retention across `.wardrobe`, `.garmentDetail`, and add-garment routes.

- [ ] **Step 1: Write failing home-policy compatibility tests**

Replace legacy summary-only category tests with assertions using full `Garment` fixtures and `WardrobeFilterPolicy`. Cover single-category replacement preserving seasons, multi-category display state, and clear-all behavior.

- [ ] **Step 2: Run wardrobe unit tests and verify failure**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/WardrobeHomePolicyTests CODE_SIGNING_ALLOWED=NO
```

Expected: compilation or assertions fail because home still uses summary-only category filtering.

- [ ] **Step 3: Refactor `WardrobeHomeView`**

Remove `onSearch` and the magnifying-glass button. Replace local `category` with `@Binding var filter`. Derive:

```swift
private var filteredGarments: [Garment] {
    WardrobeFilterPolicy.filteredGarments(garments, by: filter)
}
```

Compose `WardrobeFilterBar`, `WardrobeCategoryBrowser`, the existing grid using `filteredGarments.map(\.summary)`, and `.sheet`. Removing a chip mutates only its represented non-category value. “清空筛选” assigns `WardrobeFilter()`.

- [ ] **Step 4: Implement the two distinct empty states**

When `garments.isEmpty`, retain the existing empty-wardrobe add action. When garments exist but `filteredGarments.isEmpty`, show “没有符合条件的衣物” with “清空筛选” and “添加衣物”; ensure both actions remain reachable at large Dynamic Type.

- [ ] **Step 5: Move applied state to `RootView`**

Add:

```swift
@State private var wardrobeFilter = WardrobeFilter()
@State private var filterOwnerUserID: UUID?
```

Pass `$wardrobeFilter` and `garmentStore.garments` to home. Reset when signing out and before displaying a different user account; do not reset during detail/add route changes. Ensure previews and forced UI-test routes receive deterministic fixture garments.

- [ ] **Step 6: Run focused unit tests and commit**

Run the Step 2 command plus:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/SessionStoreTests CODE_SIGNING_ALLOWED=NO
```

Expected: both suites pass.

```bash
git add WardrobeApp/Features/Wardrobe/WardrobeHomeView.swift WardrobeApp/App/RootView.swift WardrobeAppTests/Wardrobe/WardrobeHomePolicyTests.swift
git commit -m "feat: integrate wardrobe filtering"
```

---

### Task 5: Add end-to-end interaction coverage

**Files:**
- Modify: `WardrobeAppUITests/WardrobeHomeTests.swift`
- Modify: `WardrobeApp/App/AppDependencies.swift` only if additional deterministic wardrobe fixtures are required.

**Interfaces:**
- Consumes: accessibility identifiers defined in Tasks 2–4.
- Produces: UI regression coverage for product acceptance criteria.

- [ ] **Step 1: Replace the obsolete search assertion**

Update the existing P05 test to assert `wardrobe.search` does not exist and `wardrobe.filter.open` exists with a minimum hittable frame.

- [ ] **Step 2: Add failing apply/cancel/reset UI tests**

Cover these independent journeys:

```text
open → select 春季 → close → no chip/no dot/result unchanged
open → select 春季 → complete → chip and dot visible/result filtered
reopen → reset → close → applied chip still visible
reopen → reset → complete → chips/dot removed/all garments visible
```

- [ ] **Step 3: Add failing category and compound-filter UI tests**

Cover single category without dot, category plus season preserving both, multi-category showing `wardrobe.category.multiple`, tapping one category replacing the multiple selection, removing one applied chip, and the no-results clear/add actions.

- [ ] **Step 4: Implement any deterministic fixture wiring required by the tests**

Extend only local UI-test dependency data. Do not add production-only sample branches or remote accounts. Ensure fixture garments cover at least two seasons, two colors, custom material/style/storage values, and a combination with no results.

- [ ] **Step 5: Run the wardrobe UI suite and commit**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUUITests/WardrobeHomeTests CODE_SIGNING_ALLOWED=NO
```

Expected: every `WardrobeHomeTests` test passes.

```bash
git add WardrobeAppUITests/WardrobeHomeTests.swift WardrobeApp/App/AppDependencies.swift
git commit -m "test: cover wardrobe filtering flows"
```

---

### Task 6: Validate accessibility, regression safety, and documentation

**Files:**
- Modify: `HANDOFF.md`
- Modify: implementation files from Tasks 1–5 only for verified fixes.

**Interfaces:**
- Consumes: completed feature and test suite.
- Produces: verified branch ready for review.

- [ ] **Step 1: Regenerate and inspect project drift**

Run:

```bash
xcodegen generate
git diff --check
git status --short
```

Expected: no whitespace errors. Any `YISU.xcodeproj/project.pbxproj` change must be explainable solely by `project.yml`/source discovery; do not commit personal Xcode settings.

- [ ] **Step 2: Run the complete automated suite**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO
```

Expected: all unit and UI tests pass with zero failures and zero unexpected skips.

- [ ] **Step 3: Perform the UI quality matrix**

Manually inspect on a small iPhone simulator and a large iPhone simulator in portrait and landscape. Repeat with largest accessibility Dynamic Type, VoiceOver, dark mode, high contrast, and Reduce Motion. Verify:

- filter and close controls remain at least `44×44 pt`;
- chip text is not clipped and each chip is individually reachable;
- dot state is also spoken;
- selected/expanded states are spoken;
- fixed sheet actions and home tab bar do not obscure scroll content;
- modal scrim and text meet contrast requirements in both themes.

- [ ] **Step 4: Update handoff**

Record branch, worktree, feature scope, latest commits, complete test result, manual verification result, and explicitly deferred text search/favorites/smart collections. Remove stale language that presents text search as part of the next implementation slice.

- [ ] **Step 5: Commit verification documentation**

```bash
git add HANDOFF.md
git commit -m "docs: hand off wardrobe filtering"
```

- [ ] **Step 6: Final clean-state check**

Run:

```bash
git status --short --branch
git log --oneline -8
```

Expected: only intentionally excluded local/generated Xcode changes, if any, remain; all feature and documentation commits are visible on `codex/wardrobe-filtering`.
