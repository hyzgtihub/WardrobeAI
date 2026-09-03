# YISU Garment Photo Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the authenticated P07/P08 flow that processes one photo, uploads it to private Supabase Storage, creates a user-owned garment, refreshes P05, and opens the new P09 detail.

**Architecture:** The client pre-generates the garment UUID, processes the selected image locally, uploads it to `{user_id}/{garment_id}/original.jpg`, then inserts the garment through a repository. `AddGarmentStore` owns transaction state and compensates a failed database insert by deleting the uploaded object; Supabase RLS independently enforces row and object ownership.

**Tech Stack:** Swift 6, SwiftUI, PhotosUI, UIKit/ImageIO, Swift Testing, XCUITest, Supabase Swift 2.46.0, PostgreSQL, Supabase Storage, pgTAP, iOS 17.

**Spec:** `docs/superpowers/specs/2026-09-03-yisu-garment-photo-upload-design.md`

## Global Constraints

- Keep iOS 17.0, Swift 6.0, and Supabase Swift 2.46.0; add no package.
- Use private bucket `garment-images`; persist object paths, never public or signed URLs.
- Require photo, trimmed name, category, and at least one season.
- Output metadata-free JPEG, longest edge at most 2048 px, initial quality 0.8, final size at most 5 MB.
- Do not add camera, multiple photos, cropping, AI, background/resumable upload, offline queue, or persistent drafts.
- P08 creates a row only after “完成添加”; failures preserve the current in-memory photo and form.
- Never track `Config/Secrets.xcconfig` or log tokens, email, image bytes, full paths, or raw responses.

---

### Task 1: Provision garment rows and private Storage

**Files:**
- Create: `supabase/migrations/202609030001_garments_and_private_images.sql`
- Create: `supabase/tests/garments_storage_test.sql`

**Interfaces:**
- Consumes: `public.wardrobes(id, owner_id)` and `public.set_updated_at()`.
- Produces: `public.garments`, private `garment-images`, composite ownership constraint, and row/object RLS.

- [ ] **Step 1: Write the failing pgTAP test**

Create two `auth.users`, obtain their default wardrobes, set `request.jwt.claim.role/sub`, and plan 15 assertions covering table/bucket existence, own CRUD, cross-user invisibility, foreign-wardrobe rejection, ownership-transfer rejection, and Storage path isolation. The valid insert must be explicit:

```sql
select lives_ok(
  $$insert into public.garments
    (id, user_id, wardrobe_id, image_path, name, category, seasons)
    values (
      'aaaaaaaa-0000-0000-0000-000000000001',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      (select id from public.wardrobes where owner_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and is_default),
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000001/original.jpg',
      '白衬衫', 'tops', array['spring'])$$,
  'owner inserts into owned wardrobe'
);
```

- [ ] **Step 2: Verify RED**

Run `supabase test db supabase/tests/garments_storage_test.sql`. Expected: FAIL because the table and bucket are absent.

- [ ] **Step 3: Implement the migration**

Add `unique (id, owner_id)` to wardrobes and create:

```sql
create table public.garments (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  wardrobe_id uuid not null,
  image_path text not null,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  category text not null,
  seasons text[] not null check (cardinality(seasons) > 0),
  colors text[] not null default '{}',
  brand text,
  price numeric(12,2) check (price is null or price >= 0),
  size text,
  purchase_date date,
  material text,
  style text,
  storage_location text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  foreign key (wardrobe_id, user_id) references public.wardrobes(id, owner_id) on delete cascade
);
```

Add an active `(wardrobe_id, created_at desc)` partial index, updated-at trigger, authenticated grants, and SELECT/INSERT/UPDATE/DELETE RLS requiring `auth.uid() = user_id`. Insert private bucket with 5 MB limit and JPEG MIME restriction. Storage policies require `bucket_id = 'garment-images'` and `(storage.foldername(name))[1] = auth.uid()::text`.

- [ ] **Step 4: Verify GREEN and commit**

Run `supabase db reset && supabase test db`; expect all old and new assertions to pass. Commit:

```bash
git add supabase/migrations/202609030001_garments_and_private_images.sql supabase/tests/garments_storage_test.sql
git commit -m "feat: provision private garment photos"
```

---

### Task 2: Define persisted garment models and repository contracts

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/GarmentModels.swift`
- Create: `WardrobeApp/Features/Wardrobe/GarmentRepositories.swift`
- Create: `WardrobeAppTests/Wardrobe/GarmentModelCodingTests.swift`
- Modify: `WardrobeApp/DesignSystem/Models/GarmentSummary.swift`
- Modify: `WardrobeApp/Features/Wardrobe/WardrobeSampleData.swift`

**Interfaces:**
- Produces: `Garment`, `NewGarment`, `GarmentImage`, `GarmentRepository`, `GarmentImageRepository`, and UUID-based summaries.

- [ ] **Step 1: Write failing coding/path tests**

Decode a full snake-case PostgREST fixture, encode `NewGarment`, verify optional nulls and price, then assert:

```swift
#expect(GarmentImage.objectPath(userID: userID, garmentID: garmentID)
  == "\(userID.uuidString.lowercased())/\(garmentID.uuidString.lowercased())/original.jpg")
```

- [ ] **Step 2: Verify RED**

Run:

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:YISUTests/GarmentModelCodingTests
```

Expected: missing-type compilation failures.

- [ ] **Step 3: Implement exact domain interfaces**

```swift
struct Garment: Codable, Equatable, Sendable, Identifiable {
  let id, userID, wardrobeID: UUID
  let imagePath: String
  var name: String
  var category: YISUCategory
  var seasons, colors: [String]
  var brand: String?
  var price: Decimal?
  var size: String?
  var purchaseDate: Date?
  var material, style, storageLocation, notes: String?
  let createdAt: Date
  var updatedAt: Date
  var deletedAt: Date?
}

struct NewGarment: Encodable, Equatable, Sendable {
  let id, userID, wardrobeID: UUID
  let imagePath, name: String
  let category: YISUCategory
  let seasons, colors: [String]
  let brand: String?
  let price: Decimal?
  let size: String?
  let purchaseDate: Date?
  let material, style, storageLocation, notes: String?
}

struct GarmentImage: Equatable, Sendable {
  let data: Data
  let pixelSize: CGSize
  static func objectPath(userID: UUID, garmentID: UUID) -> String
}

protocol GarmentRepository: Sendable {
  func fetchGarments(wardrobeID: UUID) async throws -> [Garment]
  func createGarment(_ input: NewGarment) async throws -> Garment
}

protocol GarmentImageRepository: Sendable {
  func uploadJPEG(_ data: Data, path: String) async throws
  func deleteImage(path: String) async throws
  func downloadImage(path: String) async throws -> Data
}
```

Use explicit coding keys and the project ISO-8601 decoder. Change `GarmentSummary.id` to UUID and `imageName` to `imagePath`; update preview fixtures with stable UUIDs.

- [ ] **Step 4: Verify GREEN and commit**

Run the focused suite plus `ModelTests`, `WardrobeHomePolicyTests`, and `GarmentDetailPolicyTests`. Commit:

```bash
git add WardrobeApp/Features/Wardrobe WardrobeApp/DesignSystem/Models WardrobeAppTests/Wardrobe
git commit -m "feat: define persisted garment models"
```

---

### Task 3: Implement Supabase data and image repositories

**Files:**
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseGarmentRepository.swift`
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseGarmentImageRepository.swift`
- Create: `WardrobeAppTests/Infrastructure/SupabaseGarmentRepositoryTests.swift`
- Modify: `WardrobeApp/App/AppDependencies.swift`

**Interfaces:**
- Consumes: Task 2 protocols and the existing Supabase client.
- Produces: live repositories and deterministic UI-test repositories.

- [ ] **Step 1: Write failing mapping tests**

Test a pure `CreatePayload`, `activeOrderColumn == "created_at"`, bucket name, and error mapping to `networkUnavailable`, `permissionDenied`, `notFound`, or `unknown`.

- [ ] **Step 2: Verify RED**

Run `-only-testing:YISUTests/SupabaseGarmentRepositoryTests`; expect repository types to be absent.

- [ ] **Step 3: Implement live SDK calls**

Use PostgREST equivalent to:

```swift
try await client.from("garments").select()
  .eq("wardrobe_id", value: wardrobeID)
  .is("deleted_at", value: nil)
  .order("created_at", ascending: false).execute().value

try await client.from("garments").insert(CreatePayload(input: input))
  .select().single().execute().value
```

Use Storage equivalent to:

```swift
try await client.storage.from(Self.bucket)
  .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: false))
try await client.storage.from(Self.bucket).remove(paths: [path])
let data = try await client.storage.from(Self.bucket).download(path: path)
```

Extend `AppDependencies` with both protocols; inject live implementations and actor-backed UI-test fakes.

- [ ] **Step 4: Verify GREEN and commit**

Run repository, dependency, configuration, and error-mapper suites. Commit:

```bash
git add WardrobeApp/Infrastructure/Supabase WardrobeApp/App/AppDependencies.swift WardrobeAppTests/Infrastructure
git commit -m "feat: connect garment storage repositories"
```

---

### Task 4: Process selected images

**Files:**
- Create: `WardrobeApp/Features/AddGarment/GarmentImageProcessor.swift`
- Create: `WardrobeAppTests/AddGarment/GarmentImageProcessorTests.swift`
- Create: `WardrobeAppTests/Fixtures/garment-photo-landscape.jpg`
- Create: `WardrobeAppTests/Fixtures/garment-photo-metadata.jpg`

**Interfaces:**
- Produces: `GarmentImageProcessor.process(_:) throws -> GarmentImage`.

- [ ] **Step 1: Write failing processing tests**

```swift
@Test func scalesAndCapsOutput() throws {
  let output = try processor.process(largeLandscapeData)
  #expect(max(output.pixelSize.width, output.pixelSize.height) == 2048)
  #expect(output.data.count <= 5 * 1024 * 1024)
}
```

Inspect the output with `CGImageSourceCopyPropertiesAtIndex` and assert GPS/EXIF dictionaries are absent. Also test invalid bytes, orientation normalization, no small-image upscaling, and uncompressible oversize failure.

- [ ] **Step 2: Verify RED**

Run `-only-testing:YISUTests/GarmentImageProcessorTests`; expect missing processor.

- [ ] **Step 3: Implement deterministic processing**

```swift
struct GarmentImageProcessor: Sendable {
  static let maximumDimension: CGFloat = 2048
  static let maximumBytes = 5 * 1024 * 1024
  static let initialQuality: CGFloat = 0.8
  static let minimumQuality: CGFloat = 0.45
  func process(_ data: Data) throws -> GarmentImage
}
```

Decode via `UIImage`, render an orientation-normalized bitmap, and encode through `CGImageDestination` using qualities `0.8, 0.7, 0.6, 0.5, 0.45` with no copied metadata. Never write source bytes to disk.

- [ ] **Step 4: Verify GREEN and commit**

Run processor tests and all `YISUTests`. Commit:

```bash
git add WardrobeApp/Features/AddGarment/GarmentImageProcessor.swift WardrobeAppTests/AddGarment WardrobeAppTests/Fixtures
git commit -m "feat: process garment photos for upload"
```

---

### Task 5: Orchestrate validation and the two-step transaction

**Files:**
- Create: `WardrobeApp/Features/AddGarment/AddGarmentModels.swift`
- Create: `WardrobeApp/Features/AddGarment/AddGarmentStore.swift`
- Create: `WardrobeAppTests/AddGarment/AddGarmentStoreTests.swift`

**Interfaces:**
- Consumes: repositories, image processor, and `UserAccount`.
- Produces: observable draft/state and `submit(account:) async -> Garment?`.

- [ ] **Step 1: Write failing transaction tests**

Test validation order, price parsing, duplicate-submit suppression, upload failure without insert, create failure with exactly one compensation delete, compensation failure preserving the primary error, and success returning one garment.

```swift
@Test func createFailureCompensatesAndPreservesDraft() async {
  let result = await store.submit(account: .fixture)
  #expect(result == nil)
  #expect(await imageRepository.events == [.upload(expectedPath), .delete(expectedPath)])
  #expect(store.draft.name == AddGarmentDraft.validFixture.name)
  #expect(store.state == .createFailed)
}
```

- [ ] **Step 2: Verify RED**

Run `-only-testing:YISUTests/AddGarmentStoreTests`; expect missing types.

- [ ] **Step 3: Implement exact state**

```swift
enum AddGarmentIssue: Equatable, Sendable {
  case photoRequired, nameRequired, categoryRequired, seasonRequired, invalidPrice
}
enum AddGarmentState: Equatable, Sendable {
  case idle, processingPhoto, editing, validating, uploadingPhoto, creatingGarment, succeeded
  case photoProcessingFailed, uploadFailed, createFailed
}
```

Make `AddGarmentStore` `@MainActor @Observable`. Its draft contains processed/preview data and every confirmed field. Guard submitting states, generate one UUID per attempt, upload, insert, and delete on insert failure. Trim name and optional strings; parse price using fixed `zh_CN` decimal rules.

- [ ] **Step 4: Verify GREEN and commit**

Run store, model, account, and session suites. Commit:

```bash
git add WardrobeApp/Features/AddGarment WardrobeAppTests/AddGarment
git commit -m "feat: orchestrate garment creation"
```

---

### Task 6: Build P07 and P08

**Files:**
- Create: `WardrobeApp/Features/AddGarment/GarmentPhotoPickerView.swift`
- Create: `WardrobeApp/Features/AddGarment/GarmentPhotoPreviewView.swift`
- Create: `WardrobeApp/Features/AddGarment/AddGarmentView.swift`
- Create: `WardrobeAppUITests/AddGarmentFlowTests.swift`
- Modify: `WardrobeApp/App/AppRoute.swift`
- Modify: `WardrobeApp/App/AppDependencies.swift`

**Interfaces:**
- Consumes: `AddGarmentStore` and UI-test scenarios.
- Produces: route cases `.garmentPhotoPicker`, `.garmentPhotoPreview`, `.addGarment` and accessible views.

- [ ] **Step 1: Write failing UI tests**

Launch with `-ui-screen add-garment` and `-ui-add-garment-scenario success|upload-failure|create-failure`. Inject a bundled fixture rather than driving the system picker. Test required errors, progress/duplicate protection, failure preserving fields, retry, reselect, and success opening P09.

- [ ] **Step 2: Verify RED**

Run `-only-testing:YISUUITests/AddGarmentFlowTests`; expect missing screens/identifiers.

- [ ] **Step 3: Implement views and accessibility contract**

Use one-image `PhotosPicker`, async `Data` loading, processed preview with “重新选择”/“使用这张照片”, full P08 form, inline validation, progress, and “完成添加”. Required identifiers:

```text
addGarment.choosePhoto
addGarment.photoPreview
addGarment.reselectPhoto
addGarment.usePhoto
addGarment.name
addGarment.category.<rawValue>
addGarment.season.<value>
addGarment.submit
addGarment.error
```

Intercept an edited-draft back action with “继续编辑” and destructive “放弃更改”. Production uses `PhotosPicker`; only injected UI-test dependencies load the fixture.

- [ ] **Step 4: Verify GREEN and commit**

Run the new UI suite and `DesignSystemGalleryTests`; ensure independent controls are at least 44×44 pt. Commit:

```bash
git add WardrobeApp/Features/AddGarment WardrobeApp/App WardrobeAppUITests/AddGarmentFlowTests.swift
git commit -m "feat: add garment photo and form screens"
```

---

### Task 7: Integrate real garments into P05 and P09

**Files:**
- Create: `WardrobeApp/Features/Wardrobe/GarmentStore.swift`
- Create: `WardrobeApp/DesignSystem/Components/PrivateGarmentImageView.swift`
- Create: `WardrobeAppTests/Wardrobe/GarmentStoreTests.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Modify: `WardrobeApp/Features/Wardrobe/WardrobeHomeView.swift`
- Modify: `WardrobeApp/Features/Wardrobe/GarmentDetailModel.swift`
- Modify: `WardrobeApp/Features/Wardrobe/GarmentDetailView.swift`
- Modify: `WardrobeApp/DesignSystem/Components/YISUGarmentCard.swift`
- Modify: `WardrobeAppUITests/WardrobeHomeTests.swift`
- Modify: `WardrobeAppUITests/GarmentDetailTests.swift`

**Interfaces:**
- Consumes: authenticated account, all repositories, and successful P08 output.
- Produces: live list loading, private image rendering, center-tab routing, list refresh, and real P09 navigation.

- [ ] **Step 1: Write failing store/navigation tests**

Test `.idle → .loading → .loaded/.failed`, wardrobe-ID forwarding, idempotent `insertCreated`, Garment-to-P09 mapping, center-tab navigation, and the created card visible after returning from P09.

- [ ] **Step 2: Verify RED**

Run `GarmentStoreTests`, `WardrobeHomeTests`, and `GarmentDetailTests`; expect P05 sample-only behavior to fail.

- [ ] **Step 3: Implement authenticated composition**

```swift
@MainActor @Observable
final class GarmentStore {
  enum State: Equatable { case idle, loading, loaded, failed }
  private(set) var state: State = .idle
  private(set) var garments: [Garment] = []
  func load(wardrobeID: UUID) async
  func insertCreated(_ garment: Garment)
}
```

Compose stores from `AppDependencies`. Load `account.wardrobe.id`, open P07 from the center tab, insert a successful P08 result, and route to its P09. Keep samples only in previews/UI-test scenarios. `PrivateGarmentImageView` downloads through the image repository, caches `UIImage` with `NSCache`, and uses the existing image-failure state; it never creates a public URL.

- [ ] **Step 4: Run full verification**

```bash
supabase test db
xcodebuild build -project YISU.xcodeproj -scheme YISU -destination 'generic/platform=iOS Simulator'
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
git diff --check
git status --short --ignored
```

Expected: every pgTAP assertion and client test passes; build/diff checks exit 0; the only ignored configuration is `Config/Secrets.xcconfig`; no generated or secret file is tracked.

- [ ] **Step 5: Perform remote manual acceptance**

Apply the migration through the agreed Supabase deployment workflow. User A adds one image and confirms P05/P09 plus row/path ownership; user B cannot select, update, or delete user A’s row/object. Inject one insert failure and confirm no extra object remains.

- [ ] **Step 6: Commit**

```bash
git add WardrobeApp WardrobeAppTests WardrobeAppUITests
git commit -m "feat: complete garment photo creation flow"
```

---

## Plan Self-Review

- Tasks 1–7 cover schema, private Storage, processing, P07/P08, compensation, real P05/P09 data, security, automated tests, and remote acceptance.
- P09 update/delete persistence, camera, multi-photo, AI, offline queues, and persistent drafts remain excluded.
- `GarmentRepository`, `GarmentImageRepository`, `GarmentImage`, `AddGarmentStore`, and `GarmentStore` are each introduced once and consumed under consistent names.
- Ownership is enforced by foreign keys and RLS in addition to client validation.
