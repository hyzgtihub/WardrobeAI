import Foundation
import Testing
@testable import YISU

@Suite("Account model coding")
struct AccountModelCodingTests {
    @Test
    func decodesProfileFromPostgREST() throws {
        let data = #"{"id":"00000000-0000-0000-0000-000000000001","nickname":"衣序用户","avatar_path":null,"language_code":"zh-Hans","notifications_enabled":true,"created_at":"2026-08-26T00:00:00Z","updated_at":"2026-08-26T00:00:00Z"}"#.data(using: .utf8)!

        let profile = try JSONDecoder.supabase.decode(UserProfile.self, from: data)

        #expect(profile.nickname == "衣序用户")
        #expect(profile.avatarPath == nil)
        #expect(profile.languageCode == "zh-Hans")
        #expect(profile.notificationsEnabled)
    }

    @Test
    func decodesDefaultWardrobeFromPostgREST() throws {
        let data = #"{"id":"10000000-0000-0000-0000-000000000001","owner_id":"00000000-0000-0000-0000-000000000001","name":"我","is_default":true}"#.data(using: .utf8)!

        let wardrobe = try JSONDecoder.supabase.decode(WardrobeIdentity.self, from: data)

        #expect(wardrobe.ownerID == UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        #expect(wardrobe.name == "我")
        #expect(wardrobe.isDefault)
    }

    @Test
    func encodesOnlyMutableProfileChanges() throws {
        let data = try JSONEncoder.supabase.encode(ProfileChanges(
            nickname: "Mia",
            languageCode: "zh-Hans",
            notificationsEnabled: false
        ))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(object.keys) == ["nickname", "language_code", "notifications_enabled"])
        #expect(object["nickname"] as? String == "Mia")
        #expect(object["notifications_enabled"] as? Bool == false)
    }
}
