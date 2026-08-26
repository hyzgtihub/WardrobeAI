import Foundation

struct AuthenticatedUser: Equatable, Sendable {
    let id: UUID
    let email: String
}

struct UserProfile: Codable, Equatable, Sendable {
    let id: UUID
    var nickname: String
    var avatarPath: String?
    var languageCode: String
    var notificationsEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case avatarPath = "avatar_path"
        case languageCode = "language_code"
        case notificationsEnabled = "notifications_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WardrobeIdentity: Codable, Equatable, Sendable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case isDefault = "is_default"
    }
}

struct UserAccount: Equatable, Sendable {
    let user: AuthenticatedUser
    var profile: UserProfile
    let defaultWardrobe: WardrobeIdentity
}

struct ProfileChanges: Encodable, Equatable, Sendable {
    let nickname: String
    let languageCode: String
    let notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case nickname
        case languageCode = "language_code"
        case notificationsEnabled = "notifications_enabled"
    }
}

extension JSONDecoder {
    static var supabase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractionalFormatter.date(from: value) {
                return date
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an ISO-8601 timestamp"
            )
        }
        return decoder
    }
}

extension JSONEncoder {
    static var supabase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
