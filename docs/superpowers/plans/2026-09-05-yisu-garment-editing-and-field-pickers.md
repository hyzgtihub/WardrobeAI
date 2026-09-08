# YISU Garment Editing and Field Pickers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct P08 draft reuse, add shared branded field pickers and calendar, and make every P09 edit—including photo replacement—persist safely to Supabase.

**Architecture:** Shared option policies and SwiftUI sheets serve P08 and P09. `AddGarmentStore` owns one create-session draft; a new `GarmentDetailStore` owns server/local detail state and serializes saves per logical field while repositories perform RLS-protected partial updates. Private photo replacement uses a new revision path and compensation instead of overwriting the live object.

**Tech Stack:** Swift 6, SwiftUI, Observation, Supabase Swift/PostgREST/Storage, PostgreSQL migrations and pgTAP, Swift Testing, XCTest UI testing

**Spec:** `docs/superpowers/specs/2026-09-05-yisu-garment-editing-and-field-pickers-design.md`

## Global Constraints

- iOS deployment target remains 17.0; do not add dependencies.
- P08 creates once through “完成添加”; it never field-autosaves.
- P09 has no edit/save mode; text saves after 800 ms or blur and selection fields save on completion.
- Failed saves do not auto-retry or enter a persistent offline queue.
- Future purchase dates are disabled; weekends remain visually equivalent to weekdays.
- Storage remains private and all database/storage access remains owner-scoped by RLS.
- Preserve but do not stage the user's local Xcode signing and Scheme changes.

---

### Task 1: Migrate multi-value fields and repository updates

**Files:**
- Create: `supabase/migrations/202609050001_garment_editing_fields.sql`
- Modify: `supabase/tests/garments_storage_test.sql`
- Modify: `WardrobeApp/Features/AddGarment/AddGarmentModels.swift`
- Modify: `WardrobeApp/Features/Wardrobe/GarmentModels.swift`
- Modify: `WardrobeApp/Features/Wardrobe/GarmentRepositories.swift`
- Modify: `WardrobeApp/Infrastructure/Supabase/SupabaseGarmentRepository.swift`
- Modify: repository model/repository tests under `WardrobeAppTests/Garment`

**Interfaces:**
- Produces `materials: [String]`, `styles: [String]`, `GarmentChanges`, `fetchGarment`, `updateGarment`, and `deleteGarment`.

- [ ] Write pgTAP and Swift tests proving old scalar values migrate to arrays, empty arrays round-trip, partial updates do not overwrite other fields, and cross-user update/delete remain blocked.
- [ ] Run focused tests and confirm RED because array columns and update APIs do not exist.
- [ ] Add `materials text[]` and `styles text[]`, migrate scalar values, add cardinality/item-length checks, drop old columns, and retain RLS grants.
- [ ] Define `GarmentChanges` with explicit optional-field clearing semantics and update Codable models to plural arrays.
- [ ] Implement PostgREST fetch-one, partial update returning the row, and delete methods; map zero-row/not-found and authorization failures.
- [ ] Run `supabase test db` and focused Swift tests; commit `feat: persist editable garment fields` without signing files.

### Task 2: Define field option and calendar policies

**Files:**
- Create: `WardrobeApp/Features/GarmentFields/GarmentFieldOptions.swift`
- Create: `WardrobeApp/Features/GarmentFields/GarmentFieldSelectionPolicy.swift`
- Create: `WardrobeApp/Features/GarmentFields/PurchaseDateCalendar.swift`
- Create: `WardrobeAppTests/GarmentFields/GarmentFieldSelectionPolicyTests.swift`
- Create: `WardrobeAppTests/GarmentFields/PurchaseDateCalendarTests.swift`
- Modify: `YISU.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces ordered category/season/color/material/style/size/storage options, custom-value normalization, summary formatting, size compatibility decisions, and a deterministic 6-row Monday-first calendar model.

- [ ] Write tests for exact frozen option order, custom trimming/deduplication/20-character limit, “四季” summary, category-size compatibility and confirmation requirements.
- [ ] Write calendar tests for Monday-first cells, selectable adjacent-month past dates, disabled future dates/month navigation, existing-date/default focus, and clear behavior.
- [ ] Run focused tests and confirm RED.
- [ ] Implement pure Sendable policies independent of SwiftUI and wall-clock time by injecting `today` and `Calendar`.
- [ ] Add sources/tests to the project, run focused tests, and commit `feat: define garment field selection policies`.

### Task 3: Build shared selection sheets and custom calendar

**Files:**
- Create: `WardrobeApp/Features/GarmentFields/GarmentSingleSelectSheet.swift`
- Create: `WardrobeApp/Features/GarmentFields/GarmentMultiSelectSheet.swift`
- Create: `WardrobeApp/Features/GarmentFields/GarmentStorageLocationSheet.swift`
- Create: `WardrobeApp/Features/GarmentFields/YISUPurchaseDateSheet.swift`
- Create: `WardrobeAppUITests/GarmentFieldPickerTests.swift`
- Modify: `YISU.xcodeproj/project.pbxproj`

**Interfaces:**
- Single-select calls `onSelect(value)` and dismisses immediately.
- Multi-select/storage/date sheets keep temporary state; only `onComplete(value)` commits, while cancel has no callback.

- [ ] Add UI tests for selection replay, cancel vs completion, custom “其他”, 44 pt targets, calendar selected/today/future semantics, clearing, and adjacent-month navigation.
- [ ] Run the new UI suite and confirm RED because picker screens/launch fixtures do not exist.
- [ ] Implement the sheets with semantic theme tokens, checkmark plus color selected state, Dynamic Type-safe layouts, VoiceOver labels/values, and stable accessibility identifiers.
- [ ] Match the approved calendar asset at `docs/superpowers/specs/assets/2026-09-05-yisu-purchase-date-selected.png`; weekends use normal enabled color and only future cells are disabled.
- [ ] Add a UI-test-only gallery route for deterministic picker states, run the UI suite, and commit `feat: add garment field pickers`.

### Task 4: Correct P08 lifecycle and integrate shared pickers

**Files:**
- Modify: `WardrobeApp/Features/AddGarment/AddGarmentStore.swift`
- Modify: `WardrobeApp/Features/AddGarment/AddGarmentView.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Modify: `WardrobeAppTests/AddGarment/AddGarmentStoreTests.swift`
- Modify: `WardrobeAppUITests/AddGarmentFlowTests.swift`

**Interfaces:**
- Produces `startNewFlow()`, `discardDraft()`, and P08 bindings to shared picker results.

- [ ] Add tests proving a successful first create cannot prefill the second flow, while reselection, validation failure, upload failure, create failure, and cancelled picker retain the current draft.
- [ ] Add UI tests for empty second flow, picker prefill/cancel/complete, custom values, date clearing, and category-size clearing confirmation.
- [ ] Run focused suites and confirm RED on stale draft and text-field placeholders.
- [ ] Reset only when P05 starts a new flow or discard is confirmed; never reset during internal photo navigation or retry.
- [ ] Replace selection-type P08 text fields/inline chips with shared rows and sheets; keep name/brand/price/notes as text inputs and persist plural arrays in create payloads.
- [ ] Run focused suites and commit `fix: isolate garment creation drafts`.

### Task 5: Implement real P09 autosave orchestration

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/GarmentDetailStore.swift`
- Create: `WardrobeAppTests/Wardrobe/GarmentDetailStoreTests.swift`
- Modify: `WardrobeApp/Features/Wardrobe/GarmentDetailModel.swift`
- Modify: `WardrobeApp/Features/Wardrobe/GarmentStore.swift`
- Modify: `YISU.xcodeproj/project.pbxproj`

**Interfaces:**
- `GarmentDetailStore` exposes editable draft, aggregate save state, per-field validation, `editText`, `commitSelection`, `flush`, `retryFailedField`, and successful garment updates.
- Same-field network writes are serialized; different field patches may progress independently.

- [ ] Write controlled-repository tests for 800 ms debounce, blur flush, no-op suppression, validation, same-field latest-value ordering, independent fields, aggregate priority, no automatic retry, server-value reload, and successful P05 update callback.
- [ ] Run focused tests and confirm RED.
- [ ] Implement per-field generation/pending slots and structured task ownership; late responses never overwrite current UI state.
- [ ] Preserve failed current-session values, expose explicit retry, and never write a durable pending queue.
- [ ] Update `GarmentStore` by persisted response only; run focused tests and commit `feat: autosave garment detail fields`.

### Task 6: Integrate P09 pickers, photo replacement, and deletion

**Files:**
- Modify: `WardrobeApp/Features/Wardrobe/GarmentDetailView.swift`
- Modify: `WardrobeApp/DesignSystem/Components/YISUGarmentDetailComponents.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Modify: `WardrobeApp/Features/AddGarment/GarmentPhotoPickerView.swift`
- Modify: `WardrobeApp/Features/AddGarment/GarmentPhotoPreviewView.swift`
- Modify: `WardrobeAppUITests/GarmentDetailTests.swift`
- Modify: image/repository tests

**Interfaces:**
- P09 uses `GarmentDetailStore`; photo confirmation uploads `<user>/<garment>/<revision>.jpg`, then patches `image_path`, then deletes the old object.

- [ ] Add UI tests for all P09 sheets, text debounce feedback, successful P05 synchronization, failed edits not polluting P05, delete confirmation, and photo cancel/success/failure.
- [ ] Add unit tests for upload failure, patch failure compensation, successful replacement plus old-object cleanup failure, and duplicate-action rejection.
- [ ] Run focused tests and confirm RED on current in-memory save and placeholder change-photo behavior.
- [ ] Compose a detail store from authenticated dependencies, wire text focus/blur and shared picker completion, and keep the page-level aggregate status lightweight.
- [ ] Implement source-aware P09 photo picker/preview routing and revision-path replacement; old image remains visible until patch success.
- [ ] Implement repository-backed delete and remove the persisted item from P05 only after success.
- [ ] Run focused unit/UI suites and commit `feat: complete editable garment details`.

### Task 7: Align documents, deploy, and verify end to end

**Files:**
- Modify: `AI数字衣橱-PRD-20260717.md`
- Modify: `AI数字衣橱-需求清单-20260717.md`
- Modify: `衣序YISU-GateA-AI原型设计需求-20260810.md`
- Modify: `docs/superpowers/specs/2026-08-14-yisu-inline-detail-autosave-design.md`
- Modify: `docs/superpowers/specs/2026-09-03-yisu-garment-photo-upload-design.md`

- [ ] Remove obsolete Gate A promises of automatic retry, durable pending queues, and sign-out blocking; record the custom calendar and plural material/style fields.
- [ ] Run `supabase test db`, generic simulator build, all Swift/unit/UI tests, `git diff --check`, project plist validation, ignored-file and secret scans.
- [ ] Deploy the new migration through the already linked Supabase project and verify local/remote migration lists match.
- [ ] Perform two-account remote acceptance for partial updates, array values, cross-account RLS, private photo replacement compensation, and cleanup generated rows/objects.
- [ ] Confirm only `Config/Secrets.xcconfig`, Supabase temp state, and the user's signing/Scheme changes remain uncommitted/ignored as appropriate.
- [ ] Commit `docs: align garment editing requirements`, then report the final commit range and preserve the feature worktree.
