import Foundation
import Testing
@testable import YISU

@Suite("Supabase garment repositories")
struct SupabaseGarmentRepositoryTests {
    @Test
    func createPayloadForwardsNewGarmentCodingContract() throws {
        let input = NewGarment(
            id: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
            userID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            wardrobeID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            imagePath: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000001/original.jpg",
            name: "白衬衫",
            category: .tops,
            seasons: ["spring"],
            colors: ["白色"],
            brand: nil,
            price: Decimal(string: "199.90"),
            size: nil,
            purchaseDate: nil,
            materials: [],
            styles: [],
            storageLocation: nil,
            notes: nil
        )

        let data = try JSONEncoder.supabase.encode(SupabaseGarmentRepository.CreatePayload(input: input))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["id"] as? String == "AAAAAAAA-0000-0000-0000-000000000001")
        #expect(object["user_id"] as? String == "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
        #expect(object["wardrobe_id"] as? String == "11111111-1111-1111-1111-111111111111")
        #expect(object["image_path"] as? String == input.imagePath)
        #expect(object["name"] as? String == "白衬衫")
        #expect(object["category"] as? String == "tops")
        #expect(object["seasons"] as? [String] == ["spring"])
        #expect((object["price"] as? NSNumber)?.decimalValue == Decimal(string: "199.90"))
    }

    @Test
    func updatePayloadForwardsOnlyRequestedChanges() throws {
        let payload = SupabaseGarmentRepository.UpdatePayload(
            changes: GarmentChanges(name: "米色风衣", styles: ["通勤"])
        )

        let data = try JSONEncoder.supabase.encode(payload)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["name"] as? String == "米色风衣")
        #expect(object["styles"] as? [String] == ["通勤"])
        #expect(object["colors"] == nil)
    }

    @Test
    func repositoryConstantsMatchDatabaseContract() {
        #expect(SupabaseGarmentRepository.activeOrderColumn == "created_at")
        #expect(SupabaseGarmentImageRepository.bucket == "garment-images")
    }

    @Test
    func mapsExpectedTransportAndServiceFailures() {
        #expect(SupabaseGarmentErrorMapper.map(URLError(.timedOut)) == .networkUnavailable)
        #expect(SupabaseGarmentErrorMapper.map(postgrestCode: "42501") == .permissionDenied)
        #expect(SupabaseGarmentErrorMapper.map(statusCode: 403) == .permissionDenied)
        #expect(SupabaseGarmentErrorMapper.map(postgrestCode: "PGRST116") == .notFound)
        #expect(SupabaseGarmentErrorMapper.map(statusCode: 404) == .notFound)
        #expect(SupabaseGarmentErrorMapper.map(TestGarmentFailure()) == .unknown)
    }
}

private struct TestGarmentFailure: Error {}
