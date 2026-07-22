# AI Digital Wardrobe MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a TestFlight-ready iPhone MVP that turns one garment photo into a private, searchable multi-role wardrobe and supports outfits, OOTD, sharing, and subscription entitlements.

**Architecture:** A SwiftUI iOS 17+ client uses feature-scoped MVVM repositories and a durable SwiftData upload queue. Supabase supplies Sign in with Apple-backed Auth, Postgres with row-level security, private Storage, and authenticated Edge Functions; Edge Functions orchestrate remove.bg and OpenAI image classification so vendor keys never reach the device.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, PhotosUI, AVFoundation, AuthenticationServices, StoreKit 2, XCTest/XCUITest, XcodeGen 2.45.4, Supabase Swift 2.46.0, Supabase Postgres/Storage/Edge Functions, Deno TypeScript, remove.bg API, OpenAI Responses API using `gpt-4.1-mini-2025-04-14` with image input and structured JSON.

## Global Constraints

- Deployment target is iOS 17.0; iPhone portrait is the MVP layout, with Dynamic Type and VoiceOver labels required.
- Bundle identifier is `com.huyouzhen.wardrobe`; product name is `Wardrobe` until branding is approved.
- All user images remain private; clients receive signed URLs only and third-party API keys exist only in Edge Function secrets.
- AI output is editable advice. A failed AI or background-removal request must still permit manual garment creation.
- Current role scopes Wardrobe, Outfits, and OOTD; records from different roles never appear together.
- Free entitlement: one role and 50 successful AI imports per account. Pro entitlement: five roles and 1,000 successful AI imports per monthly billing period. StoreKit product ID: `com.huyouzhen.wardrobe.pro.monthly`.
- MVP uses category-card view only. Per-role view selection, community, automatic outfit generation, virtual try-on, shared editing, resale, and child growth prediction are excluded.
- Server timestamps are UTC; UI displays the device time zone. `recentlyAdded` means the preceding 30 days; seasons use Northern Hemisphere month mapping.

---

## Locked File Map

- `project.yml`, `Config/*.xcconfig`: reproducible Xcode project and environment injection.
- `WardrobeApp/App/`: composition root, navigation, dependency container, session/current-role state.
- `WardrobeApp/Core/`: shared models, repository protocols, Supabase adapters, upload queue, image quality analysis, subscription service.
- `WardrobeApp/Features/{Auth,Roles,Wardrobe,Capture,Outfits,OOTD,Settings}/`: one feature per folder with View, ViewModel, and feature-specific components.
- `WardrobeAppTests/` and `WardrobeAppUITests/`: unit, integration-contract, and end-to-end UI tests.
- `supabase/migrations/`: schema, RLS, storage policies, quota RPCs, deletion workflow.
- `supabase/functions/process-garment/`: authenticated idempotent AI pipeline.
- `supabase/functions/delete-account/`: authenticated account erasure.

## Shared Interfaces

```swift
protocol AuthRepository { func signInWithApple(idToken: String, nonce: String) async throws; func signOut() async throws; func deleteAccount() async throws }
protocol RoleRepository { func list() async throws -> [WardrobeRole]; func create(_ draft: RoleDraft) async throws -> WardrobeRole; func update(_ role: WardrobeRole) async throws }
protocol GarmentRepository { func list(roleID: UUID, filter: GarmentFilter) async throws -> [Garment]; func createManual(_ draft: GarmentDraft) async throws -> Garment; func update(_ garment: Garment) async throws; func delete(id: UUID) async throws -> GarmentDeleteImpact }
protocol ImportRepository { func enqueue(roleID: UUID, jpeg: Data) async throws -> UUID; func retry(jobID: UUID) async }
protocol OutfitRepository { func list(roleID: UUID) async throws -> [Outfit]; func save(_ draft: OutfitDraft) async throws -> Outfit }
protocol OOTDRepository { func month(roleID: UUID, containing date: Date) async throws -> [OOTDEntry]; func save(_ draft: OOTDDraft) async throws -> OOTDEntry }
protocol EntitlementService { var tier: EntitlementTier { get async }; func purchasePro() async throws; func restore() async throws }
```

### Task 1: Reproducible iOS shell and CI baseline

**Files:** Create `project.yml`, `Config/Debug.xcconfig`, `Config/Release.xcconfig`, `WardrobeApp/App/WardrobeApp.swift`, `WardrobeApp/App/RootView.swift`, `WardrobeAppTests/SmokeTests.swift`, `.gitignore`, `.github/workflows/ios.yml`.

**Produces:** Buildable `Wardrobe` app, `WardrobeAppTests`, and `WardrobeAppUITests` schemes.

- [ ] Install XcodeGen 2.45.4, generate the project, and pin Supabase Swift exactly to 2.46.0 in `project.yml`; keep Supabase URL/publishable key in untracked `Config/Secrets.xcconfig` with a committed `.example` file.
- [ ] Write `SmokeTests.testRootShowsSignedOutState()` first, asserting the accessibility identifier `auth.signInWithApple` exists in `RootView` when no session is present.
- [ ] Run `xcodegen generate && xcodebuild test -scheme Wardrobe -destination 'platform=iOS Simulator,name=iPhone 16'`; expect the smoke test to fail before `RootView` exists, then pass after minimal app composition is added.
- [ ] Add CI using the same command and cache only Swift Package Manager downloads.
- [ ] Commit: `chore: bootstrap iOS app and CI`.

### Task 2: Database schema, storage, and tenant isolation

**Files:** Create `supabase/config.toml`, `supabase/migrations/202607170001_core_schema.sql`, `supabase/tests/rls.sql`, `WardrobeApp/Core/Models/*.swift`, `WardrobeAppTests/ModelCodingTests.swift`.

**Produces:** Codable models `WardrobeRole`, `Garment`, `Outfit`, `OOTDEntry`; RLS-protected tables and private buckets `garment-originals`, `garment-cutouts`, `ootd-photos`.

- [ ] Write pgTAP tests proving user A cannot select, insert, update, or delete user B's role, garment, outfit, OOTD, or storage object; prove outfit/OOTD garment IDs must belong to the same role.
- [ ] Run `supabase start && supabase test db`; expect failures because tables do not exist.
- [ ] Add enums `role_type`, `garment_status`, `repurchase_rating`, `processing_status`; create normalized tables plus `outfit_items` and `ootd_items`, indexes on `(role_id, created_at)`, `(role_id, category)`, and `(role_id, last_worn_at)`.
- [ ] Add `handle_new_user()` trigger creating role `我`, RLS policies based on `auth.uid()`, private storage policies using the first object-path segment as user ID, and generated Swift models with matching snake-case coding keys.
- [ ] Run pgTAP and `xcodebuild test ... -only-testing:WardrobeAppTests/ModelCodingTests`; expect all pass.
- [ ] Commit: `feat: add wardrobe schema and tenant isolation`.

### Task 3: Sign in with Apple, session restoration, and role context

**Files:** Create `Core/Networking/SupabaseClientFactory.swift`, `Features/Auth/AuthRepositoryLive.swift`, `Features/Auth/SignInView.swift`, `App/SessionStore.swift`, `Features/Roles/RoleRepositoryLive.swift`, `Features/Roles/RoleSwitcher.swift`; tests in `AuthViewModelTests.swift` and `CurrentRoleStoreTests.swift`.

**Consumes:** Supabase schema and `AuthRepository`/`RoleRepository` interfaces. **Produces:** restored session and a non-optional `CurrentRoleStore.roleID` for authenticated screens.

- [ ] Write tests for nonce generation, Apple token forwarding, session restoration, default-role selection, role switch persistence, and sign-out reset.
- [ ] Run targeted tests and verify they fail with missing repositories.
- [ ] Implement `SignInWithAppleButton`, SHA-256 nonce handling, Supabase `signInWithIdToken(provider: .apple, ...)`, auth-state observation, and Keychain-backed session behavior supplied by Supabase.
- [ ] Implement role switcher and prohibit creating a second role when entitlement is `.free`; show the paywall rather than submitting the insert.
- [ ] Run tests plus a UI test that signs in through an injected fake repository; expect pass.
- [ ] Commit: `feat: add authentication and role context`.

### Task 4: Garment repository, categories, filters, and smart labels

**Files:** Create `Features/Wardrobe/GarmentRepositoryLive.swift`, `WardrobeViewModel.swift`, `WardrobeHomeView.swift`, `GarmentCard.swift`, `GarmentFilterSheet.swift`, `GarmentDetailView.swift`, `Core/Domain/SmartLabelResolver.swift`; tests `SmartLabelResolverTests.swift`, `WardrobeViewModelTests.swift`.

**Produces:** `SmartLabelResolver.labels(for:now:) -> [SmartLabel]` ordered favorite, repurchase, do-not-buy, seasonal, recently-worn, recently-added; `GarmentFilter` supporting text, category, season, color, status, and smart collection.

- [ ] Write deterministic tests using a fixed clock for 30-day recently-added, OOTD-derived recently-worn, Northern Hemisphere seasons, and the maximum two card labels with user labels first.
- [ ] Verify tests fail, then implement the resolver and repository queries scoped by current role.
- [ ] Build the approved hybrid home: role switcher, search/filter/import actions, smart collections, category chips, three-column cutout cards, loading/empty/error states.
- [ ] Add edit/delete flows; deletion first calls an impact RPC and displays outfit/OOTD counts. On confirmation, replace historical item references with snapshots before removing private images.
- [ ] Run unit and snapshot/accessibility UI tests; commit `feat: add searchable smart wardrobe`.

### Task 5: Capture, local quality checks, and durable upload queue

**Files:** Create `Features/Capture/CameraView.swift`, `PhotoSourceSheet.swift`, `ImageQualityAnalyzer.swift`, `ImportDraftView.swift`, `Core/Upload/UploadJob.swift`, `UploadQueue.swift`, `UploadWorker.swift`; tests `ImageQualityAnalyzerTests.swift`, `UploadQueueTests.swift`.

**Produces:** `ImageQualityAnalyzer.analyze(_:) -> [ImageQualityIssue]` and idempotent `ImportRepository.enqueue(roleID:jpeg:)`.

- [ ] Add fixture tests for blur (Laplacian variance below 80), darkness (mean luminance below 0.12), unsupported data, queue persistence, duplicate tap idempotency, retry backoff `2, 4, 8, 16, 30` seconds, and app relaunch recovery.
- [ ] Verify failures; implement `PhotosPicker`, AVFoundation camera capture, JPEG normalization to sRGB with maximum long edge 2048 px and quality 0.85, plus warnings users may override.
- [ ] Store pending JPEGs in Application Support and metadata in SwiftData; upload to `<user-id>/<job-id>/original.jpg`, invoke `process-garment`, and never delete local input until the server marks the job complete.
- [ ] Test airplane-mode enqueue, background/foreground, network restoration, and repeated Save taps; commit `feat: add resilient garment import queue`.

### Task 6: Server-side garment processing pipeline

**Files:** Create `supabase/functions/process-garment/index.ts`, `providers/remove-bg.ts`, `providers/openai.ts`, `schema.ts`, `index.test.ts`, migration `202607170002_import_jobs.sql`.

**Produces:** authenticated `POST process-garment { jobId, roleId, originalPath }` returning `{ jobId, status }`; persisted `import_jobs` state machine `queued|processing|needs_review|failed`.

- [ ] Write Deno tests for invalid JWT, wrong-owner role/path, repeated job ID, remove.bg failure fallback, OpenAI schema rejection, quota exhaustion, and successful cutout/classification.
- [ ] Implement atomic `reserve_ai_import(job_id)` RPC so only completed processing consumes quota and retries never double-charge.
- [ ] Call remove.bg with `size=auto`; store PNG cutout privately. Call OpenAI Responses with image input and a strict schema containing `category`, `subcategory`, `primaryColor`, `seasons[]`, and confidence values from 0...1.
- [ ] On either vendor failure, persist the original image and return `needs_review` with nullable suggestions; never expose vendor error bodies or secrets to the client.
- [ ] Run `deno test --allow-env supabase/functions/process-garment` and local integration calls with stub servers; commit `feat: process garment images securely`.

### Task 7: Import review and manual-save fallback

**Files:** Create `Features/Capture/ImportReviewView.swift`, `ImportReviewViewModel.swift`, `ManualGarmentForm.swift`; tests `ImportReviewViewModelTests.swift` and `ImportFlowUITests.swift`.

- [ ] Test AI-prefilled fields, confidence-independent editability, original-image fallback, required category validation, correction flag, successful save, and retry-safe double submission.
- [ ] Implement polling with foreground refresh for `import_jobs`, editable form fields, retry action, and “手动填写并保存” on failure.
- [ ] Save confirmed fields as the authoritative garment and `was_ai_corrected` when any suggested value changes.
- [ ] Run unit/UI tests for success, partial failure, total failure, and offline recovery; commit `feat: add garment review and fallback`.

### Task 8: Outfits, OOTD calendar, and deletion-safe history

**Files:** Create `Features/Outfits/*`, `Features/OOTD/*`, migration `202607170003_history_snapshots.sql`; tests `OutfitViewModelTests.swift`, `OOTDViewModelTests.swift`, `HistoryIntegrityTests.swift`.

- [ ] Write tests requiring at least two garments per outfit, same-role references, one OOTD per role/date, outfit-or-direct-garment creation, and `last_worn_at` recalculation when OOTD changes or is deleted.
- [ ] Implement outfit grid selection and saved outfit preview; implement month calendar with date detail and optional user photo.
- [ ] Add database trigger/RPC that updates `last_worn_at`, and immutable item snapshots (`name`, `category`, `cutout_path`) used when a garment is deleted.
- [ ] Run database, unit, and UI tests; commit `feat: add outfits and OOTD history`.

### Task 9: Share images and privacy controls

**Files:** Create `Core/Sharing/ShareRenderer.swift`, `Features/Outfits/OutfitShareView.swift`, `Features/OOTD/OOTDShareView.swift`, tests `ShareRendererTests.swift`.

- [ ] Write tests that output a 1080x1350 image, include only user-selected garments/date/caption, omit private object URLs and metadata, and work offline from cached images.
- [ ] Implement SwiftUI `ImageRenderer` templates and invoke the system share sheet only after an explicit tap.
- [ ] Add permission-purpose copy and privacy links in Settings; no public feed or automatic upload is introduced.
- [ ] Run tests and manually inspect light/dark/Dynamic Type output; commit `feat: add private opt-in sharing`.

### Task 10: StoreKit entitlements, quotas, and role limits

**Files:** Create `Core/Subscription/StoreKitEntitlementService.swift`, `Features/Settings/PaywallView.swift`, `StoreKit/Wardrobe.storekit`, Edge Function `sync-entitlement/index.ts`, migration `202607170004_entitlements.sql`; tests `EntitlementTests.swift`, `QuotaTests.sql`.

- [ ] Write StoreKit Test tests for purchase, restore, expiration, billing retry, offline cached entitlement, one-role free limit, five-role Pro limit, 50/1,000 AI quotas, and downgrade without deleting existing roles.
- [ ] Implement StoreKit 2 `Product.products`, verified transaction listener, restore, and signed transaction submission to the server; server remains authoritative for quota checks.
- [ ] On downgrade, retain all data but allow edits only within the most recently used role until Pro returns; block new AI imports after quota exhaustion while preserving manual creation.
- [ ] Run StoreKit configuration tests and database quota tests; commit `feat: add subscription entitlements`.

### Task 11: Account deletion, observability, analytics, and release hardening

**Files:** Create `supabase/functions/delete-account/index.ts`, `Features/Settings/AccountView.swift`, `Core/Analytics/Analytics.swift`, `Core/Logging/AppLogger.swift`, `PrivacyInfo.xcprivacy`, tests `AccountDeletionTests.swift`, `CriticalJourneyUITests.swift`, `docs/release/testflight-checklist.md`.

- [ ] Write deletion tests proving second confirmation, reauthentication requirement, removal of storage objects/domain rows/auth user, and idempotent retry; write analytics tests ensuring no image, free-text note, child name, or raw user ID enters events.
- [ ] Implement events: `sign_in_completed`, `first_import_completed`, `garment_saved`, `outfit_created`, `ootd_created`, `role_created`, `quota_reached`, `purchase_completed`; use random installation/session IDs only.
- [ ] Add structured logs with job ID and sanitized error code; add server latency/error counters for remove.bg, OpenAI, and total processing, with alert thresholds of >5% failures over 15 minutes or p95 >30 seconds.
- [ ] Run the critical journey: sign in → first import → manual correction → second role paywall → purchase → child garment → outfit → OOTD → share → relaunch restore → account deletion.
- [ ] Run full `xcodebuild test`, `supabase test db`, and Deno tests; archive Release with zero warnings, complete privacy manifest and TestFlight checklist; commit `chore: harden MVP for TestFlight`.

## Delivery Gates

1. **Gate A — Private digital wardrobe:** Tasks 1–4; authenticated role-isolated CRUD and approved hybrid home work with seeded images.
2. **Gate B — Low-friction AI import:** Tasks 5–7; offline-safe capture reaches editable garment within 30 seconds at p95 in the seed-user region.
3. **Gate C — Retention loop:** Tasks 8–9; outfit, OOTD, history, and opt-in sharing work without breaking deleted-item history.
4. **Gate D — TestFlight business MVP:** Tasks 10–11; subscriptions, quotas, erasure, telemetry, accessibility, and full regression pass.

## Assumptions Requiring Product Validation, Not Engineering Choice

- The fixed free/Pro limits are launch-test defaults and may change after cost and conversion analysis without schema changes.
- The first closed TestFlight cohort is 30–50 users recruited by the founder; baseline metrics are collected for 14 days before setting retention targets.
- Supabase project region must be selected only after confirming the legal entity and target launch geography; production launch is blocked until privacy counsel approves cross-border image processing and child-related data language.
- remove.bg and OpenAI are behind provider interfaces so a China-hosted alternative can replace either without changing iOS feature code.

## Official References Used for Locked Choices

- [Apple Sign in with Apple](https://developer.apple.com/documentation/SigninwithApple) and [SwiftUI button guidance](https://developer.apple.com/documentation/signinwithapple/displaying-sign-in-with-apple-buttons-in-your-app).
- [Apple PhotosPicker](https://developer.apple.com/documentation/photosui/photospicker) and [StoreKit subscription status](https://developer.apple.com/documentation/storekit/subscriptioninfo) APIs.
- [Supabase Swift installation](https://supabase.com/docs/reference/swift/installing), [iOS SwiftUI quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/ios-swiftui), and [authenticated Edge Functions](https://supabase.com/docs/guides/functions/auth).
- [remove.bg HTTP API](https://www.remove.bg/a/api-docs) with server-side API key handling.
- OpenAI Responses API image input with strict structured output, pinned to `gpt-4.1-mini-2025-04-14` for reproducible MVP classification.
