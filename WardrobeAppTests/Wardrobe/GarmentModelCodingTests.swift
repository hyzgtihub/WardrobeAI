import Foundation
import Testing
@testable import YISU

@Suite("Garment model coding")
struct GarmentModelCodingTests {
    @Test
    func decodesFullGarmentFromPostgREST() throws {
        let data = #"{"id":"aaaaaaaa-0000-0000-0000-000000000001","user_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","wardrobe_id":"10000000-0000-0000-0000-000000000001","image_path":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000001/original.jpg","name":"白色亚麻衬衫","category":"tops","seasons":["spring","summer"],"colors":["白色"],"brand":"MUJI","price":299.90,"size":"M","purchase_date":"2026-04-18","materials":["亚麻","棉"],"styles":["通勤","简约"],"storage_location":"主卧衣橱·上层","notes":"适合浅色长裤","created_at":"2026-09-03T08:15:30.123Z","updated_at":"2026-09-03T08:16:00Z","deleted_at":null}"#.data(using: .utf8)!

        let garment = try JSONDecoder.supabase.decode(Garment.self, from: data)

        #expect(garment.id == UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001"))
        #expect(garment.userID == UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"))
        #expect(garment.wardrobeID == UUID(uuidString: "10000000-0000-0000-0000-000000000001"))
        #expect(garment.category == .tops)
        #expect(garment.seasons == ["spring", "summer"])
        #expect(garment.colors == ["白色"])
        #expect(garment.materials == ["亚麻", "棉"])
        #expect(garment.styles == ["通勤", "简约"])
        #expect(garment.brand == "MUJI")
        #expect(garment.price == Decimal(string: "299.90"))
        #expect(garment.purchaseDate == Self.date("2026-04-18"))
        #expect(garment.deletedAt == nil)
    }

    @Test
    func encodesNewGarmentWithSnakeCaseDatePriceAndNullOptionals() throws {
        let input = NewGarment(
            id: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
            userID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            wardrobeID: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            imagePath: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/aaaaaaaa-0000-0000-0000-000000000001/original.jpg",
            name: "白衬衫",
            category: .tops,
            seasons: ["spring"],
            colors: [],
            brand: nil,
            price: Decimal(string: "299.90"),
            size: nil,
            purchaseDate: Self.date("2026-04-18"),
            materials: [],
            styles: [],
            storageLocation: nil,
            notes: nil
        )

        let data = try JSONEncoder.supabase.encode(input)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["user_id"] as? String == "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
        #expect(object["wardrobe_id"] as? String == "10000000-0000-0000-0000-000000000001")
        #expect(object["image_path"] as? String == input.imagePath)
        #expect(object["category"] as? String == "tops")
        #expect(object["purchase_date"] as? String == "2026-04-18")
        #expect((object["price"] as? NSNumber)?.decimalValue == Decimal(string: "299.90"))
        #expect(object["brand"] is NSNull)
        #expect(object["size"] is NSNull)
        #expect(object["materials"] as? [String] == [])
        #expect(object["styles"] as? [String] == [])
        #expect(object["storage_location"] is NSNull)
        #expect(object["notes"] is NSNull)
    }

    @Test
    func garmentChangesOmitsUnchangedFieldsAndEncodesExplicitClears() throws {
        let changes = GarmentChanges(
            name: "新名称",
            colors: [],
            brand: .clear,
            purchaseDate: .clear,
            materials: ["羊毛", "丝绸"]
        )

        let data = try JSONEncoder.supabase.encode(changes)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["name"] as? String == "新名称")
        #expect(object["colors"] as? [String] == [])
        #expect(object["brand"] is NSNull)
        #expect(object["purchase_date"] is NSNull)
        #expect(object["materials"] as? [String] == ["羊毛", "丝绸"])
        #expect(object["category"] == nil)
        #expect(object["styles"] == nil)
    }

    @Test
    func buildsStablePrivateStorageObjectPath() {
        let userID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let garmentID = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!

        #expect(
            GarmentImage.objectPath(userID: userID, garmentID: garmentID)
                == "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-0000-0000-0000-000000000001/original.jpg"
        )
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
