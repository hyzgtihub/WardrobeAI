# YISU Supabase Auth, Profile, and Default Wardrobe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace demo authentication with real Supabase email/password sessions and persist one profile plus one default wardrobe named “我” for every user.

**Architecture:** The SwiftUI app depends on small repository protocols and a main-actor `SessionStore`; only adapters under `Infrastructure/Supabase` import Supabase. PostgreSQL migrations create profiles and wardrobes atomically from `auth.users`, while RLS remains the final authorization boundary.

**Tech Stack:** iOS 17, Swift 6, SwiftUI Observation, Swift Testing, XCUITest, XcodeGen, Supabase Swift 2.46.0, Supabase Auth, PostgreSQL migrations, pgTAP.

**Spec:** `docs/superpowers/specs/2026-08-25-yisu-supabase-auth-profile-default-wardrobe-design.md`

## Global Constraints

- Preserve the accepted P01/P02/P05 visuals and the main navigation copy `衣橱｜添加衣物｜我的`.
- Scope is registration, sign-in, session restoration, sign-out, profile read/update, and one default wardrobe named `我`.
- Do not implement garments, image storage, P09 autosave, offline sync, password reset, email verification, or account deletion.
- The app may contain only the Supabase Project URL and Publishable Key; never add `service_role`, database passwords, passwords, access tokens, or refresh tokens to source or logs.
- `auth.users.email` is authoritative; do not duplicate email in `public.profiles`.
- All public tables must have RLS enabled and policies scoped to `authenticated` plus `auth.uid()`.
- Unit and UI tests must use mocks and must not depend on a live Supabase account.
- Make one commit after each task only when its focused verification passes.

---

## File Map

- `project.yml`: pins Supabase Swift and injects the two non-secret build-setting names into generated Info.plist.
- `Config/Secrets.xcconfig.example`: documents safe placeholder syntax; `Config/Secrets.xcconfig` remains ignored.
- `WardrobeApp/Infrastructure/Configuration/SupabaseConfiguration.swift`: validates and exposes URL/key without logging values.
- `supabase/migrations/202608260001_auth_profiles_wardrobes.sql`: schema, triggers, grants, and RLS.
- `supabase/tests/auth_profiles_wardrobes_test.sql`: pgTAP schema and cross-user authorization tests.
- `WardrobeApp/Features/Account/AccountModels.swift`: domain account/profile/wardrobe models and coding keys.
- `WardrobeApp/Features/Account/AccountRepositories.swift`: repository protocols, session events, domain errors, and profile changes.
- `WardrobeApp/App/SessionStore.swift`: main-actor session state machine and retry policy.
- `WardrobeApp/Infrastructure/Supabase/SupabaseClientFactory.swift`: sole construction point for `SupabaseClient`.
- `WardrobeApp/Infrastructure/Supabase/SupabaseAuthRepository.swift`: Auth adapter and auth-state stream.
- `WardrobeApp/Infrastructure/Supabase/SupabaseProfileRepository.swift`: profile select/update adapter.
- `WardrobeApp/Infrastructure/Supabase/SupabaseWardrobeRepository.swift`: default wardrobe select adapter.
- `WardrobeApp/App/AppDependencies.swift`: live and UI-test dependency composition.
- `WardrobeApp/App/YISUApp.swift`: owns and injects `SessionStore`.
- `WardrobeApp/App/RootView.swift`: renders routes from session state.
- `WardrobeApp/Features/Auth/SignInView.swift`: binds submit/loading/error state to session actions.
- `WardrobeApp/Features/Auth/SignUpView.swift`: binds registration/loading/error state to session actions.
- `WardrobeApp/Features/Profile/ProfileView.swift`: minimal profile display, nickname edit, and sign-out action reached from `我的`.
- `WardrobeAppTests/Configuration/SupabaseConfigurationTests.swift`: configuration validation.
- `WardrobeAppTests/Account/AccountModelCodingTests.swift`: PostgREST coding contracts.
- `WardrobeAppTests/App/SessionStoreTests.swift`: state-machine behavior.
- `WardrobeAppTests/Infrastructure/SupabaseErrorMapperTests.swift`: stable domain error mapping.
- `WardrobeAppUITests/AuthSessionFlowTests.swift`: deterministic mocked login/register/sign-out flows.

---

### Task 1: Supabase Package and Safe Runtime Configuration

**Files:**
- Modify: `project.yml`
- Modify: `Config/Secrets.xcconfig.example`
- Create: `WardrobeApp/Infrastructure/Configuration/SupabaseConfiguration.swift`
- Create: `WardrobeAppTests/Configuration/SupabaseConfigurationTests.swift`
- Regenerate: `YISU.xcodeproj`

**Interfaces:**
- Consumes: `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` build settings from ignored `Config/Secrets.xcconfig`.
- Produces: `SupabaseConfiguration.load(from:) throws -> SupabaseConfiguration`, with `url: URL` and `publishableKey: String`.

- [ ] **Step 1: Add failing configuration tests**

```swift
import Foundation
import Testing
@testable import YISU

@Suite("Supabase configuration")
struct SupabaseConfigurationTests {
    @Test func loadsValidValues() throws {
        let configuration = try SupabaseConfiguration.load(from: [
            "SupabaseURL": "https://project.supabase.co",
            "SupabasePublishableKey": "publishable-test-key-1234567890"
        ])
        #expect(configuration.url.absoluteString == "https://project.supabase.co")
        #expect(configuration.publishableKey == "publishable-test-key-1234567890")
    }

    @Test(arguments: ["", "https:", "http://project.supabase.co", "not-a-url"])
    func rejectsInvalidURL(value: String) {
        #expect(throws: SupabaseConfiguration.Error.invalidURL) {
            try SupabaseConfiguration.load(from: [
                "SupabaseURL": value,
                "SupabasePublishableKey": "publishable-test-key-1234567890"
            ])
        }
    }

    @Test func rejectsMissingKey() {
        #expect(throws: SupabaseConfiguration.Error.missingPublishableKey) {
            try SupabaseConfiguration.load(from: ["SupabaseURL": "https://project.supabase.co"])
        }
    }
}
```

- [ ] **Step 2: Run the focused test and confirm the red state**

```bash
xcodegen generate
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/SupabaseConfigurationTests
```

Expected: compilation fails because `SupabaseConfiguration` does not exist.

- [ ] **Step 3: Pin the package and expose Info.plist keys**

Add to `project.yml`:

```yaml
packages:
  Supabase:
    url: https://github.com/supabase/supabase-swift
    exactVersion: 2.46.0
```

Add `- package: Supabase` to `YISU.dependencies`, then add under the app target's base settings:

```yaml
INFOPLIST_KEY_SupabaseURL: "$(SUPABASE_URL)"
INFOPLIST_KEY_SupabasePublishableKey: "$(SUPABASE_PUBLISHABLE_KEY)"
```

- [ ] **Step 4: Implement strict configuration parsing**

```swift
import Foundation

struct SupabaseConfiguration: Equatable, Sendable {
    enum Error: Swift.Error, Equatable {
        case invalidURL
        case missingPublishableKey
    }

    let url: URL
    let publishableKey: String

    static func load(from values: [String: Any] = Bundle.main.infoDictionary ?? [:]) throws -> Self {
        guard
            let rawURL = values["SupabaseURL"] as? String,
            let url = URL(string: rawURL),
            url.scheme == "https",
            url.host?.hasSuffix(".supabase.co") == true
        else { throw Error.invalidURL }

        guard
            let key = values["SupabasePublishableKey"] as? String,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw Error.missingPublishableKey }

        return Self(url: url, publishableKey: key)
    }
}
```

- [ ] **Step 5: Regenerate and verify**

Run the Step 2 command again. Expected: `SupabaseConfigurationTests` pass and the package resolves at exactly `2.46.0`.

- [ ] **Step 6: Commit the safe configuration layer**

```bash
git add project.yml YISU.xcodeproj Config/Secrets.xcconfig.example WardrobeApp/Infrastructure/Configuration/SupabaseConfiguration.swift WardrobeAppTests/Configuration/SupabaseConfigurationTests.swift
git commit -m "build: configure Supabase client dependency"
```

Do not add `Config/Secrets.xcconfig`.

---

### Task 2: PostgreSQL Schema, Automatic Provisioning, and RLS

**Files:**
- Create: `supabase/config.toml`
- Create: `supabase/migrations/202608260001_auth_profiles_wardrobes.sql`
- Create: `supabase/tests/auth_profiles_wardrobes_test.sql`

**Interfaces:**
- Consumes: Supabase `auth.users` and `auth.uid()`.
- Produces: `public.profiles`, `public.wardrobes`, `public.handle_new_user()`, `public.set_updated_at()`, and authenticated select/update permissions defined in the spec.

- [ ] **Step 1: Initialize the checked-in Supabase CLI layout**

```bash
supabase init
```

Keep the generated `supabase/config.toml`; local state under `supabase/.temp` and `supabase/.branches` is already ignored.

- [ ] **Step 2: Write pgTAP expectations before the migration**

Create a test transaction that calls `plan(14)`, then checks:

```sql
select has_table('public', 'profiles', 'profiles exists');
select has_table('public', 'wardrobes', 'wardrobes exists');
select col_is_pk('public', 'profiles', 'id', 'profiles.id is the primary key');
select policies_are('public', 'profiles', array['profiles_select_own', 'profiles_update_own']);
select policies_are('public', 'wardrobes', array['wardrobes_select_own']);
```

The same file must create two test users, assert one profile and one default wardrobe per user, set request JWT claims for user A, assert A sees only A's rows, assert an update of B affects zero rows, then switch to `anon` and assert both tables return zero rows. End with `select * from finish(); rollback;`.

- [ ] **Step 3: Run the database tests and confirm the red state**

```bash
supabase start
supabase test db
```

Expected: pgTAP reports missing `profiles` and `wardrobes` objects.

- [ ] **Step 4: Implement tables and update trigger**

The migration must create `pgcrypto`, both tables, nickname constraints, `wardrobes_one_default_per_owner`, and this timestamp trigger function:

```sql
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
```

Attach it before update on both tables.

- [ ] **Step 5: Implement atomic user provisioning**

```sql
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;

  insert into public.wardrobes (owner_id, name, is_default)
  values (new.id, '我', true)
  on conflict (owner_id) where is_default = true do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
```

- [ ] **Step 6: Enable RLS and add exact policies**

```sql
alter table public.profiles enable row level security;
alter table public.wardrobes enable row level security;

create policy profiles_select_own on public.profiles
for select to authenticated using ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles
for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);
create policy wardrobes_select_own on public.wardrobes
for select to authenticated using ((select auth.uid()) = owner_id);

revoke all on public.profiles from anon;
revoke all on public.wardrobes from anon;
grant select, update on public.profiles to authenticated;
grant select on public.wardrobes to authenticated;
```

- [ ] **Step 7: Reset locally and verify all database tests**

```bash
supabase db reset
supabase test db
```

Expected: all 14 pgTAP assertions pass.

- [ ] **Step 8: Commit database behavior**

```bash
git add supabase/config.toml supabase/migrations/202608260001_auth_profiles_wardrobes.sql supabase/tests/auth_profiles_wardrobes_test.sql
git commit -m "feat: provision protected user accounts"
```

---

### Task 3: Account Domain Models and Repository Contracts

**Files:**
- Create: `WardrobeApp/Features/Account/AccountModels.swift`
- Create: `WardrobeApp/Features/Account/AccountRepositories.swift`
- Create: `WardrobeAppTests/Account/AccountModelCodingTests.swift`

**Interfaces:**
- Consumes: snake-case JSON returned by `profiles` and `wardrobes`.
- Produces: `AuthenticatedUser`, `UserProfile`, `ProfileChanges`, `WardrobeIdentity`, `UserAccount`, `AuthSessionEvent`, `AccountError`, `AuthRepository`, `ProfileRepository`, and `WardrobeRepository` with the exact signatures in the design spec.

- [ ] **Step 1: Add failing decoding and encoding tests**

```swift
@Test func decodesProfileFromPostgREST() throws {
    let data = #"{"id":"00000000-0000-0000-0000-000000000001","nickname":"衣序用户","avatar_path":null,"language_code":"zh-Hans","notifications_enabled":true,"created_at":"2026-08-26T00:00:00Z","updated_at":"2026-08-26T00:00:00Z"}"#.data(using: .utf8)!
    let profile = try JSONDecoder.supabase.decode(UserProfile.self, from: data)
    #expect(profile.nickname == "衣序用户")
    #expect(profile.notificationsEnabled)
}

@Test func encodesOnlyMutableProfileChanges() throws {
    let data = try JSONEncoder.supabase.encode(ProfileChanges(nickname: "Mia", languageCode: "zh-Hans", notificationsEnabled: false))
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(Set(object.keys) == ["nickname", "language_code", "notifications_enabled"])
}
```

- [ ] **Step 2: Run the focused tests and confirm compilation fails**

```bash
xcodegen generate
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/AccountModelCodingTests
```

- [ ] **Step 3: Implement immutable identities and explicit coding keys**

Define the models from the spec plus:

```swift
struct UserAccount: Equatable, Sendable {
    let user: AuthenticatedUser
    var profile: UserProfile
    let defaultWardrobe: WardrobeIdentity
}

struct ProfileChanges: Encodable, Equatable, Sendable {
    let nickname: String
    let languageCode: String
    let notificationsEnabled: Bool
}
```

Use explicit `CodingKeys`; add internal `JSONDecoder.supabase` and `JSONEncoder.supabase` configured with ISO-8601 dates.

- [ ] **Step 4: Define repository contracts and stable domain errors**

```swift
enum AuthSessionEvent: Equatable, Sendable {
    case signedIn(AuthenticatedUser)
    case signedOut
    case tokenRefreshed(AuthenticatedUser)
}

enum AccountError: Error, Equatable, Sendable {
    case invalidCredentials
    case emailAlreadyRegistered
    case networkUnavailable
    case accountDataUnavailable
    case invalidConfiguration
    case unknown
}
```

Define the contracts explicitly:

```swift
protocol AuthRepository: Sendable {
    func sessionEvents() -> AsyncStream<AuthSessionEvent>
    func currentUser() async throws -> AuthenticatedUser?
    func signUp(email: String, password: String) async throws -> AuthenticatedUser
    func signIn(email: String, password: String) async throws -> AuthenticatedUser
    func signOut() async throws
}

protocol ProfileRepository: Sendable {
    func fetchProfile() async throws -> UserProfile
    func updateProfile(_ changes: ProfileChanges) async throws -> UserProfile
}

protocol WardrobeRepository: Sendable {
    func fetchDefaultWardrobe() async throws -> WardrobeIdentity
}
```

- [ ] **Step 5: Run the focused tests**

Run the Step 2 command again. Expected: all account coding tests pass.

- [ ] **Step 6: Commit domain contracts**

```bash
git add WardrobeApp/Features/Account WardrobeAppTests/Account
git commit -m "feat: define account repository contracts"
```

---

### Task 4: SessionStore State Machine with Mocks

**Files:**
- Create: `WardrobeApp/App/SessionStore.swift`
- Create: `WardrobeAppTests/App/SessionStoreTests.swift`

**Interfaces:**
- Consumes: the three repository protocols from Task 3.
- Produces: `SessionState`, `SessionFailure`, and `@MainActor @Observable final class SessionStore` with `restore()`, `signIn(email:password:)`, `signUp(email:password:)`, `retryAccountLoad()`, `updateProfile(_:)`, and `signOut()`.

- [ ] **Step 1: Create actor-backed repository spies**

In the test file, define `AuthRepositorySpy`, `ProfileRepositorySpy`, and `WardrobeRepositorySpy` with configurable `Result` values and call counters. Use `AsyncStream.makeStream(of:)` to expose auth events without live networking.

- [ ] **Step 2: Add failing state transition tests**

Cover these exact scenarios:

```swift
@Test @MainActor func restoreWithoutUserEndsSignedOut() async
@Test @MainActor func restoreLoadsProfileAndWardrobeIntoReadyAccount() async
@Test @MainActor func signInMapsInvalidCredentialsAndPreservesSignedOutState() async
@Test @MainActor func accountLoadRetriesThreeTimesBeforeFailure() async
@Test @MainActor func signOutClearsAccountEvenWhenRemoteSignOutThrows() async
@Test @MainActor func signedOutEventClearsAnExistingAccount() async
@Test @MainActor func profileUpdateReplacesReadyProfile() async
```

- [ ] **Step 3: Run the focused tests and confirm the red state**

```bash
xcodegen generate
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/SessionStoreTests
```

Expected: compilation fails because `SessionStore` does not exist.

- [ ] **Step 4: Implement the state and public actions**

```swift
enum SessionState: Equatable {
    case restoring
    case signedOut
    case loadingAccount(AuthenticatedUser)
    case ready(UserAccount)
    case failed(SessionFailure)
}

@MainActor @Observable
final class SessionStore {
    private(set) var state: SessionState = .restoring
    private(set) var isSubmitting = false
    private(set) var submissionError: AccountError?
}
```

Keep the supplied password only as a call argument. Never assign it to a property or log it.

- [ ] **Step 5: Implement bounded account loading and event observation**

Fetch profile and wardrobe with `async let`. Retry only `.accountDataUnavailable` three times with delays of 100 ms then 250 ms; inject the sleeper as `@Sendable (Duration) async -> Void` so tests use an immediate sleeper. Start one auth event task and cancel it in `deinit`.

- [ ] **Step 6: Run the focused tests**

Run the Step 3 command again. Expected: all seven `SessionStoreTests` pass.

- [ ] **Step 7: Commit the state machine**

```bash
git add WardrobeApp/App/SessionStore.swift WardrobeAppTests/App/SessionStoreTests.swift
git commit -m "feat: manage authenticated session state"
```

---

### Task 5: Live Supabase Repository Adapters

**Files:**
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseClientFactory.swift`
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseErrorMapper.swift`
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseAuthRepository.swift`
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseProfileRepository.swift`
- Create: `WardrobeApp/Infrastructure/Supabase/SupabaseWardrobeRepository.swift`
- Create: `WardrobeAppTests/Infrastructure/SupabaseErrorMapperTests.swift`

**Interfaces:**
- Consumes: `SupabaseConfiguration` and repository protocols.
- Produces: live adapters used only by `AppDependencies.live()`.

- [ ] **Step 1: Write failing pure error-mapping tests**

Define table-driven tests for mapper inputs: `invalid_credentials`, `user_already_exists`, `email_exists`, `NSURLErrorNotConnectedToInternet`, `NSURLErrorTimedOut`, and an unknown error. Expected outputs are `.invalidCredentials`, `.emailAlreadyRegistered`, `.networkUnavailable`, `.networkUnavailable`, and `.unknown` respectively.

- [ ] **Step 2: Run focused tests and confirm failure**

```bash
xcodegen generate
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/SupabaseErrorMapperTests
```

- [ ] **Step 3: Implement the client factory and mapper**

```swift
enum SupabaseClientFactory {
    static func make(configuration: SupabaseConfiguration) -> SupabaseClient {
        SupabaseClient(
            supabaseURL: configuration.url,
            supabaseKey: configuration.publishableKey
        )
    }
}
```

The mapper may inspect stable Auth error codes and `URLError.Code`; it must not include raw server messages in user-facing strings or logs.

- [ ] **Step 4: Implement AuthRepository**

Use `client.auth.session` for validated restoration, `signUp(email:password:)`, `signIn(email:password:)`, `signOut()`, and `client.auth.authStateChanges`. Convert SDK users into `AuthenticatedUser`; if the email is absent, map to `.unknown`.

- [ ] **Step 5: Implement profile and wardrobe repositories**

Use these queries:

```swift
try await client.from("profiles").select().single().execute().value
try await client.from("profiles").update(changes).select().single().execute().value
try await client.from("wardrobes").select().eq("is_default", value: true).single().execute().value
```

Do not send `user_id` filters as the authorization mechanism; RLS scopes the authenticated result. Map missing rows to `.accountDataUnavailable`.

- [ ] **Step 6: Run focused model, mapper, and configuration tests**

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/SupabaseConfigurationTests -only-testing:YISUTests/AccountModelCodingTests -only-testing:YISUTests/SupabaseErrorMapperTests
```

Expected: all focused tests pass without network access.

- [ ] **Step 7: Commit live adapters**

```bash
git add WardrobeApp/Infrastructure WardrobeAppTests/Infrastructure
git commit -m "feat: connect account repositories to Supabase"
```

---

### Task 6: App Composition and Authentication UI Integration

**Files:**
- Create: `WardrobeApp/App/AppDependencies.swift`
- Modify: `WardrobeApp/App/YISUApp.swift`
- Modify: `WardrobeApp/App/RootView.swift`
- Modify: `WardrobeApp/Features/Auth/SignInView.swift`
- Modify: `WardrobeApp/Features/Auth/SignUpView.swift`
- Create: `WardrobeApp/Features/Profile/ProfileView.swift`
- Modify: `WardrobeApp/App/AppRoute.swift`
- Modify: `WardrobeAppUITests/AuthSessionFlowTests.swift`

**Interfaces:**
- Consumes: `SessionStore` and live repository adapters.
- Produces: a runnable app with deterministic `-ui-auth-scenario` mock modes: `signed-out`, `login-success`, `login-failure`, `registration-failure`, and `signed-in`.

- [ ] **Step 1: Add failing UI tests**

Add tests that launch with the mock scenario and assert:

```swift
func testSuccessfulLoginReachesWardrobe()
func testFailedLoginKeepsEnteredEmailAndShowsError()
func testRegistrationFailureKeepsEnteredEmail()
func testSignedInProfileCanSignOutToLogin()
```

Use existing accessibility identifiers plus new identifiers `auth.error`, `profile.screen`, and `profile.signOut`. Never type real Supabase credentials.

- [ ] **Step 2: Run the focused UI tests and confirm the red state**

```bash
xcodegen generate
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUUITests/AuthSessionFlowTests
```

- [ ] **Step 3: Add dependency composition**

`AppDependencies.live()` loads `SupabaseConfiguration`, creates one Supabase client, constructs all three repositories, then creates `SessionStore`. `AppDependencies.uiTest(arguments:)` returns deterministic mocks selected by `-ui-auth-scenario`; it must not construct a Supabase client.

- [ ] **Step 4: Make the App own session state**

`YISUApp` creates dependencies once, injects `SessionStore` into `RootView`, and starts `restore()` in one `.task`. Configuration failure renders a non-secret configuration error with retry unavailable instead of crashing.

- [ ] **Step 5: Drive RootView from SessionState**

- `.restoring` renders a progress state.
- `.signedOut` renders sign-in/register routes.
- `.loadingAccount` renders the existing wardrobe creation/loading state.
- `.ready` renders P05 and routes the `我的` action to `ProfileView`.
- `.failed` renders a retry action calling `retryAccountLoad()`.

Keep `-ui-screen` behavior for existing visual tests by selecting UI-test dependencies before session restoration.

- [ ] **Step 6: Bind P01 and P02 to async actions**

Disable repeated submission while `SessionStore.isSubmitting` is true. Map `.invalidCredentials`, `.emailAlreadyRegistered`, `.networkUnavailable`, and `.unknown` to the existing inline error treatments. Preserve email/password text after failures; clear password only after successful authentication.

- [ ] **Step 7: Add minimal profile editing and sign-out**

Display nickname and authenticated email, allow a trimmed 1–30 character nickname update through `ProfileChanges`, and call `SessionStore.signOut()` from `profile.signOut`. Do not add avatar upload or email editing.

- [ ] **Step 8: Run focused unit and UI tests**

```bash
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:YISUTests/SessionStoreTests -only-testing:YISUUITests/AuthSessionFlowTests
```

Expected: all session unit tests and four auth UI tests pass.

- [ ] **Step 9: Commit app integration**

```bash
git add WardrobeApp/App WardrobeApp/Features/Auth WardrobeApp/Features/Profile WardrobeAppUITests/AuthSessionFlowTests.swift
git commit -m "feat: integrate Supabase account session UI"
```

---

### Task 7: Development Project Migration and End-to-End Verification

**Files:**
- Modify: `README.md`
- Verify only: `Config/Secrets.xcconfig`

**Interfaces:**
- Consumes: the user's configured development Supabase project and all prior tasks.
- Produces: applied remote migrations, verified account provisioning, documented setup, and full regression evidence.

- [ ] **Step 1: Link the CLI without storing the database password**

```bash
read -r "YISU_SUPABASE_PROJECT_REF?Supabase project ref: "
supabase link --project-ref "$YISU_SUPABASE_PROJECT_REF"
unset YISU_SUPABASE_PROJECT_REF
```

Enter the database password only in the CLI prompt or approved local secret mechanism. Never place it in a command, plan edit, shell history, or Git-tracked file.

- [ ] **Step 2: Review and push migrations**

```bash
supabase db diff --linked
supabase db push --dry-run
supabase db push
```

Expected: the dry run lists only the profiles/wardrobes migration; the push succeeds.

- [ ] **Step 3: Verify Auth dashboard settings**

In the development Supabase project, Email provider is enabled and Confirm email is disabled for this MVP phase. Do not change production settings in this task.

- [ ] **Step 4: Perform a disposable end-to-end account check**

Register a disposable development email in the app, confirm P05 appears, terminate and relaunch the app to confirm restoration, open `我的`, change nickname, sign out, and confirm P01 appears. Delete the disposable user from the development dashboard after recording pass/fail only; do not record its password or tokens.

- [ ] **Step 5: Document local setup**

Add README steps for copying `Secrets.xcconfig.example`, using `https:/$()/...`, generating the Xcode project, starting local Supabase tests, and running the iOS test command. Explicitly state that `service_role` and database passwords are forbidden in the app.

- [ ] **Step 6: Run the complete verification suite**

```bash
supabase test db
xcodegen generate
xcodebuild build -project YISU.xcodeproj -scheme YISU -destination 'generic/platform=iOS Simulator'
xcodebuild test -project YISU.xcodeproj -scheme YISU -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
git diff --check
git status --short
```

Expected: all pgTAP assertions pass, build exits 0, all unit/UI tests pass, diff check exits 0, and `Config/Secrets.xcconfig` is absent from status.

- [ ] **Step 7: Commit documentation**

```bash
git add README.md
git commit -m "docs: document Supabase development setup"
```

- [ ] **Step 8: Request code review before integration**

Use `superpowers:requesting-code-review`; resolve any correctness or security findings, rerun Step 6, then use `superpowers:finishing-a-development-branch` to present merge/push options. Do not push or merge without the user's explicit authorization.
