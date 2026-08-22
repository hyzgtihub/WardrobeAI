# YISU P01–P05 Hi-Fi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the accepted P01, P02, P03, P04, and P05 Hi-Fi screens as interactive SwiftUI views backed by deterministic local state.

**Architecture:** A lightweight root route owns the local flow; each feature view owns only its form or display state and emits actions through closures. Shared authentication controls and the existing YISU design-system components carry visual states, while pure policy/state types make validation and transitions unit-testable without a backend.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest UI Testing, Xcode 26.

**Spec:** `docs/superpowers/specs/2026-08-22-yisu-hifi-auth-onboarding-wardrobe-design.md`

## Global Constraints

- Use Figma nodes P01 `294:5`, P02 `478:124`, P03/P04 `480:456`, and P05 `294:48` as the visual source.
- Reuse `YISUTheme`, `YISUButton`, `YISUContentStateView`, `YISUCategoryFilter`, `YISUGarmentGrid`, and `YISUBottomNavigation`.
- Implement local deterministic UI state only; no network, database, cloud sync, or photo upload.
- Keep every independent action at least `44×44pt`; errors must include text and not rely on color alone.
- Preserve and exclude the existing uncommitted `YISU.xcodeproj/xcshareddata/xcschemes/YISU.xcscheme` change.
- Main agent executes serially and reviews once after each task; no routine subagents.

---

### Task 1: Authentication Controls and Form Policies

**Files:**
- Modify: `WardrobeApp/DesignSystem/Foundation/YISUTheme.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUAuthScaffold.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUAuthField.swift`
- Create: `WardrobeApp/DesignSystem/Components/YISUAgreementCheckbox.swift`
- Create: `WardrobeApp/Features/Auth/AuthFormPolicy.swift`
- Create: `WardrobeAppTests/Auth/AuthFormPolicyTests.swift`

**Interfaces:**
- Produces: `AuthFormPolicy.canSignIn(email:password:agreementAccepted:) -> Bool`.
- Produces: `AuthFormPolicy.signUpIssue(email:password:confirmation:agreementAccepted:) -> SignUpIssue?`.
- Produces: `YISUAuthField`, `YISUPasswordField`, `YISUAgreementCheckbox`, and `YISUAuthScaffold`.

- [ ] **Step 1: Write failing policy tests**

```swift
@Test func validSignInCanSubmit() {
    #expect(AuthFormPolicy.canSignIn(
        email: "mia@example.com", password: "password", agreementAccepted: true
    ))
}

@Test(arguments: [
    SignUpIssue.invalidEmail,
    .passwordTooShort,
    .passwordMismatch,
    .agreementRequired
])
func signUpIssuesAreRepresentable(_ issue: SignUpIssue) {
    #expect(issue.message.isEmpty == false)
}
```

- [ ] **Step 2: Run RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/AuthFormPolicyTests
```

Expected: FAIL because `AuthFormPolicy` and `SignUpIssue` do not exist.

- [ ] **Step 3: Implement the minimal policies and shared controls**

```swift
enum SignUpIssue: Equatable {
    case invalidEmail, passwordTooShort, passwordMismatch, agreementRequired

    var message: String {
        switch self {
        case .invalidEmail: "请输入有效邮箱"
        case .passwordTooShort: "密码至少 8 位"
        case .passwordMismatch: "两次输入的密码不一致"
        case .agreementRequired: "请先阅读并同意服务条款与隐私政策"
        }
    }
}

enum AuthFormPolicy {
    static func canSignIn(email: String, password: String, agreementAccepted: Bool) -> Bool {
        email.contains("@") && !password.isEmpty && agreementAccepted
    }

    static func signUpIssue(
        email: String,
        password: String,
        confirmation: String,
        agreementAccepted: Bool
    ) -> SignUpIssue? {
        if !email.contains("@") { return .invalidEmail }
        if password.count < 8 { return .passwordTooShort }
        if password != confirmation { return .passwordMismatch }
        if !agreementAccepted { return .agreementRequired }
        return nil
    }
}
```

`YISUAuthField` uses `TextField`, a visible label, an optional error string, `textContentType`, keyboard type, focused border, and a `58pt` minimum height. `YISUPasswordField` uses `SecureField`/`TextField` plus a labeled `44pt` visibility button. `YISUAgreementCheckbox` exposes `isSelected` and separate terms/privacy actions. `YISUAuthScaffold` provides the V3B glow background, brand header, safe-area scrolling, and keyboard dismissal.

- [ ] **Step 4: Run GREEN and existing component tests**

Run the Task 1 test command, then:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/FoundationTests -only-testing:YISUTests/ControlBehaviorTests
```

Expected: all selected tests pass.

- [ ] **Step 5: Commit Task 1 files only**

```bash
git add WardrobeApp/DesignSystem WardrobeApp/Features/Auth/AuthFormPolicy.swift WardrobeAppTests/Auth/AuthFormPolicyTests.swift YISU.xcodeproj/project.pbxproj
git commit -m "feat: add YISU authentication controls"
```

---

### Task 2: P01 Login and P02 Registration

**Files:**
- Modify: `WardrobeApp/Features/Auth/SignInView.swift`
- Create: `WardrobeApp/Features/Auth/SignUpView.swift`
- Create: `WardrobeApp/Features/Auth/AuthSubmissionState.swift`
- Create: `WardrobeAppTests/Auth/AuthSubmissionStateTests.swift`
- Modify: `WardrobeAppUITests/SmokeTests.swift`

**Interfaces:**
- Consumes: Task 1 authentication controls and `AuthFormPolicy`.
- Produces: `SignInView(onRegister:onForgotPassword:onSubmit:)`.
- Produces: `SignUpView(onBack:onCreated:)` and `AuthSubmissionState` with `idle`, `submitting`, `emailExists`, and `serviceFailure`.

- [ ] **Step 1: Write failing submission-state and UI tests**

```swift
@Test func submittingBlocksRepeatAction() {
    #expect(AuthSubmissionState.submitting.allowsSubmission == false)
}
```

```swift
func testP01ReachesRegistration() {
    let app = XCUIApplication()
    app.launch()
    app.buttons["auth.register"].tap()
    XCTAssertTrue(app.staticTexts["创建账号"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Run RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/AuthSubmissionStateTests -only-testing:YISUUITests/SmokeTests
```

Expected: FAIL because the state and P01 registration route are absent.

- [ ] **Step 3: Implement P01 and P02**

P01 matches node `294:5`, replacing the Apple-login skeleton. P02 is one view whose state selects the accepted six visual outcomes: default, password issue, email exists, submitting, service failure, and agreement required. `onSubmit` receives validated values; the local demo advances through injected closures only.

```swift
enum AuthSubmissionState: Equatable {
    case idle, submitting, emailExists, serviceFailure
    var allowsSubmission: Bool { self == .idle }
}
```

- [ ] **Step 4: Run GREEN and review both previews**

Run the Task 2 test command. In Xcode Canvas, verify P01 default/filled and P02 six named previews use V3B tokens, maintain visible errors, and keep fields reachable with the keyboard.

- [ ] **Step 5: Commit Task 2 files only**

```bash
git add WardrobeApp/Features/Auth WardrobeAppTests/Auth WardrobeAppUITests/SmokeTests.swift YISU.xcodeproj/project.pbxproj
git commit -m "feat: implement P01 and P02 authentication screens"
```

---

### Task 3: P03/P04 Local Onboarding Flow and Root Routing

**Files:**
- Create: `WardrobeApp/App/AppRoute.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Create: `WardrobeApp/Features/Onboarding/WardrobeSetupState.swift`
- Create: `WardrobeApp/Features/Onboarding/WardrobeSetupView.swift`
- Create: `WardrobeApp/Features/Onboarding/CurrentWardrobeView.swift`
- Create: `WardrobeAppTests/Onboarding/WardrobeSetupStateTests.swift`
- Create: `WardrobeAppUITests/OnboardingFlowTests.swift`

**Interfaces:**
- Produces: `AppRoute` cases `signIn`, `signUp`, `onboarding`, `wardrobe`.
- Produces: `WardrobeSetupState` cases `creating`, `creationFailed`, `created`, `currentRole`, `loadingCurrentRole`, `currentRoleFailed`.
- Produces: retry and continue closures; no service dependency.

- [ ] **Step 1: Write failing route/state tests**

```swift
@Test func failuresCanRetry() {
    #expect(WardrobeSetupState.creationFailed.allowsRetry)
    #expect(WardrobeSetupState.currentRoleFailed.allowsRetry)
    #expect(!WardrobeSetupState.creating.allowsRetry)
}
```

UI test launch arguments use `-ui-screen onboarding` and `-ui-state creationFailed` to assert the retry button is reachable.

- [ ] **Step 2: Run RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/WardrobeSetupStateTests -only-testing:YISUUITests/OnboardingFlowTests
```

Expected: FAIL because onboarding types and launch routing do not exist.

- [ ] **Step 3: Implement one state-driven P03/P04 flow**

Use `YISUContentStateView(state: .error, ...)` for both failure states and the accepted centered `ProgressView` card for both loading states. P03 creation success advances to P04 current role; P04 current role continues to `.wardrobe`. RootView continues to honor `-design-system-gallery` and additionally parses UI-test screen/state arguments.

- [ ] **Step 4: Run GREEN and route regression**

Run the Task 3 test command plus `YISUUITests/SmokeTests`. Expected: P01 remains the normal default entry and all six P03/P04 states are reachable through launch arguments.

- [ ] **Step 5: Commit Task 3 files only**

```bash
git add WardrobeApp/App WardrobeApp/Features/Onboarding WardrobeAppTests/Onboarding WardrobeAppUITests YISU.xcodeproj/project.pbxproj
git commit -m "feat: implement P03 and P04 onboarding flow"
```

---

### Task 4: P05 Wardrobe Home and Confirmed Garment Assets

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/WardrobeHomeView.swift`
- Create: `WardrobeApp/Features/Wardrobe/WardrobeSampleData.swift`
- Modify: `WardrobeApp/DesignSystem/Models/GarmentSummary.swift`
- Modify: `WardrobeApp/DesignSystem/Components/YISUGarmentCard.swift`
- Create: four image sets under `WardrobeApp/Resources/Assets.xcassets/Garments/`
- Copy source PNGs from `figma-deliverables/衣序YISU-GateA原型与UI设计/assets/garments/`
- Create: `WardrobeAppTests/Wardrobe/WardrobeHomePolicyTests.swift`
- Create: `WardrobeAppUITests/WardrobeHomeTests.swift`

**Interfaces:**
- Produces: `WardrobeSampleData.garments` with four accepted items and category metadata.
- Produces: `WardrobeHomePolicy.items(_:matching:) -> [GarmentSummary]`.
- Produces: `WardrobeHomeView(onSearch:onAdd:onSelectGarment:onProfile:)`.

- [ ] **Step 1: Write failing filter and UI tests**

```swift
@Test func topsFilterKeepsTwoItems() {
    let result = WardrobeHomePolicy.items(WardrobeSampleData.garments, matching: .tops)
    #expect(result.map(\.title) == ["白色亚麻衬衫", "蓝色针织上衣"])
}
```

UI test launches `-ui-screen wardrobe`, changes category, opens one garment card, and verifies search/add/profile controls exist with `44pt` minimum frames.

- [ ] **Step 2: Run RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/WardrobeHomePolicyTests -only-testing:YISUUITests/WardrobeHomeTests
```

Expected: FAIL because P05 types and image assets do not exist.

- [ ] **Step 3: Import exact images and implement P05**

Create named images `garment-white-linen-shirt`, `garment-powder-blue-knit`, `garment-beige-trench`, and `garment-black-knit-dress`. Extend `GarmentSummary` with a `category: YISUCategory` field, update existing fixtures, and assign the accepted blush/blue/khaki/lavender backgrounds by semantic token. Keep filtering local and emit all destinations through closures.

- [ ] **Step 4: Run GREEN and gallery regression**

Run the Task 4 test command and `YISUUITests/DesignSystemGalleryTests`. Expected: P05 behavior and all existing shared-component accessibility tests pass.

- [ ] **Step 5: Commit Task 4 files only**

```bash
git add WardrobeApp/Features/Wardrobe WardrobeApp/DesignSystem WardrobeApp/Resources/Assets.xcassets WardrobeAppTests/Wardrobe WardrobeAppUITests/WardrobeHomeTests.swift YISU.xcodeproj/project.pbxproj
git commit -m "feat: implement P05 wardrobe home"
```

---

### Task 5: Unified Verification and Handoff

**Files:**
- Modify only files required by failures found during verification.

**Interfaces:**
- Consumes all previous tasks; produces a green implementation branch.

- [ ] **Step 1: Build**

```bash
xcodebuild build -project YISU.xcodeproj -scheme YISU -destination 'generic/platform=iOS Simulator'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 2: Run the complete test suite**

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: all Swift Testing and XCTest UI tests pass with zero failures.

- [ ] **Step 3: Audit scope and repository hygiene**

```bash
git diff --check
git status --short
rg -n 'import (SwiftData|CoreData|Alamofire)' WardrobeApp/Features/Auth WardrobeApp/Features/Onboarding WardrobeApp/Features/Wardrobe
```

Expected: no whitespace errors, no unintended backend dependency, and the pre-existing Scheme change remains uncommitted.

- [ ] **Step 4: Confirm task commits and preserved local change**

```bash
git log --oneline -8
git diff -- YISU.xcodeproj/xcshareddata/xcschemes/YISU.xcscheme
```

Expected: the four task commits are present and the only intended uncommitted file is the preserved Scheme change. If verification finds a failure, return to the task that owns that file, complete its RED/GREEN cycle, and commit the exact owning-task files before repeating Task 5.

- [ ] **Step 5: Report and request remote synchronization**

Report implemented pages, test counts, the preserved Scheme change, and branch status. Push only after explicit user authorization.
