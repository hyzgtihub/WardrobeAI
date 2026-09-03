import Foundation

@MainActor
struct AppDependencies {
    let sessionStore: SessionStore
    let garmentRepository: any GarmentRepository
    let garmentImageRepository: any GarmentImageRepository

    static func live() throws -> Self {
        let configuration = try SupabaseConfiguration.load()
        let client = SupabaseClientFactory.make(configuration: configuration)
        return Self(
            sessionStore: SessionStore(
                authRepository: SupabaseAuthRepository(client: client),
                profileRepository: SupabaseProfileRepository(client: client),
                wardrobeRepository: SupabaseWardrobeRepository(client: client)
            ),
            garmentRepository: SupabaseGarmentRepository(client: client),
            garmentImageRepository: SupabaseGarmentImageRepository(client: client)
        )
    }

    static func uiTest(arguments: [String]) -> Self {
        let scenario = argument(after: "-ui-auth-scenario", in: arguments) ?? "signed-out"
        let addGarmentScenario = argument(after: "-ui-add-garment-scenario", in: arguments) ?? "success"
        return Self(
            sessionStore: SessionStore(
                authRepository: UITestAuthRepository(scenario: scenario),
                profileRepository: UITestProfileRepository(),
                wardrobeRepository: UITestWardrobeRepository(),
                sleep: { _ in }
            ),
            garmentRepository: UITestGarmentRepository(scenario: addGarmentScenario),
            garmentImageRepository: UITestGarmentImageRepository(scenario: addGarmentScenario)
        )
    }

    static func shouldUseUITestDependencies(arguments: [String]) -> Bool {
        arguments.contains("-ui-screen") ||
        arguments.contains("-ui-auth-scenario") ||
        arguments.contains("-ui-add-garment-scenario") ||
        arguments.contains("-design-system-gallery")
    }

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

private struct UITestAuthRepository: AuthRepository {
    let scenario: String

    func sessionEvents() -> AsyncStream<AuthSessionEvent> {
        AsyncStream { $0.finish() }
    }

    func currentUser() async throws -> AuthenticatedUser? {
        scenario == "signed-in" ? Self.user : nil
    }

    func signUp(email: String, password: String) async throws -> AuthenticatedUser {
        guard scenario != "registration-failure" else { throw AccountError.emailAlreadyRegistered }
        return Self.user
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        guard scenario == "login-success" else { throw AccountError.invalidCredentials }
        return Self.user
    }

    func signOut() async throws {}

    private static let user = AuthenticatedUser(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "mia@example.com"
    )
}

private actor UITestProfileRepository: ProfileRepository {
    private var profile = UserProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        nickname: "Mia",
        avatarPath: nil,
        languageCode: "zh-CN",
        notificationsEnabled: true,
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    func fetchProfile() async throws -> UserProfile { profile }

    func updateProfile(_ changes: ProfileChanges, for userID: UUID) async throws -> UserProfile {
        profile.nickname = changes.nickname
        profile.languageCode = changes.languageCode
        profile.notificationsEnabled = changes.notificationsEnabled
        profile.updatedAt = Date()
        return profile
    }
}

private struct UITestWardrobeRepository: WardrobeRepository {
    func fetchDefaultWardrobe() async throws -> WardrobeIdentity {
        WardrobeIdentity(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            ownerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "我",
            isDefault: true
        )
    }
}

private actor UITestGarmentRepository: GarmentRepository {
    let scenario: String
    private var garments: [Garment] = []

    init(scenario: String) {
        self.scenario = scenario
    }

    func fetchGarments(wardrobeID: UUID) async throws -> [Garment] {
        garments.filter { $0.wardrobeID == wardrobeID && $0.deletedAt == nil }
    }

    func createGarment(_ input: NewGarment) async throws -> Garment {
        guard scenario != "create-failure" else { throw GarmentRepositoryError.unknown }
        let timestamp = Date(timeIntervalSince1970: 0)
        let garment = Garment(
            id: input.id,
            userID: input.userID,
            wardrobeID: input.wardrobeID,
            imagePath: input.imagePath,
            name: input.name,
            category: input.category,
            seasons: input.seasons,
            colors: input.colors,
            brand: input.brand,
            price: input.price,
            size: input.size,
            purchaseDate: input.purchaseDate,
            material: input.material,
            style: input.style,
            storageLocation: input.storageLocation,
            notes: input.notes,
            createdAt: timestamp,
            updatedAt: timestamp,
            deletedAt: nil
        )
        garments.insert(garment, at: 0)
        return garment
    }
}

private actor UITestGarmentImageRepository: GarmentImageRepository {
    let scenario: String
    private var images: [String: Data] = [:]

    init(scenario: String) {
        self.scenario = scenario
    }

    func uploadJPEG(_ data: Data, path: String) async throws {
        guard scenario != "upload-failure" else { throw GarmentRepositoryError.networkUnavailable }
        images[path] = data
    }

    func deleteImage(path: String) async throws {
        images[path] = nil
    }

    func downloadImage(path: String) async throws -> Data {
        guard let data = images[path] else { throw GarmentRepositoryError.notFound }
        return data
    }
}
