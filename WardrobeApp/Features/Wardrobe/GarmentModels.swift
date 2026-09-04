import CoreGraphics
import Foundation

struct Garment: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let userID: UUID
    let wardrobeID: UUID
    var imagePath: String
    var name: String
    var category: YISUCategory
    var seasons: [String]
    var colors: [String]
    var brand: String?
    var price: Decimal?
    var size: String?
    var purchaseDate: Date?
    var materials: [String]
    var styles: [String]
    var storageLocation: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case wardrobeID = "wardrobe_id"
        case imagePath = "image_path"
        case name
        case category
        case seasons
        case colors
        case brand
        case price
        case size
        case purchaseDate = "purchase_date"
        case materials
        case styles
        case storageLocation = "storage_location"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        wardrobeID: UUID,
        imagePath: String,
        name: String,
        category: YISUCategory,
        seasons: [String],
        colors: [String],
        brand: String?,
        price: Decimal?,
        size: String?,
        purchaseDate: Date?,
        materials: [String],
        styles: [String],
        storageLocation: String?,
        notes: String?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.wardrobeID = wardrobeID
        self.imagePath = imagePath
        self.name = name
        self.category = category
        self.seasons = seasons
        self.colors = colors
        self.brand = brand
        self.price = price
        self.size = size
        self.purchaseDate = purchaseDate
        self.materials = materials
        self.styles = styles
        self.storageLocation = storageLocation
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        wardrobeID = try container.decode(UUID.self, forKey: .wardrobeID)
        imagePath = try container.decode(String.self, forKey: .imagePath)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(YISUCategory.self, forKey: .category)
        seasons = try container.decode([String].self, forKey: .seasons)
        colors = try container.decode([String].self, forKey: .colors)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        price = try container.decodeIfPresent(Decimal.self, forKey: .price)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        purchaseDate = try DateOnlyCoding.decodeIfPresent(from: container, forKey: .purchaseDate)
        materials = try container.decodeIfPresent([String].self, forKey: .materials) ?? []
        styles = try container.decodeIfPresent([String].self, forKey: .styles) ?? []
        storageLocation = try container.decodeIfPresent(String.self, forKey: .storageLocation)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(wardrobeID, forKey: .wardrobeID)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(seasons, forKey: .seasons)
        try container.encode(colors, forKey: .colors)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(size, forKey: .size)
        try DateOnlyCoding.encodeIfPresent(purchaseDate, to: &container, forKey: .purchaseDate)
        try container.encode(materials, forKey: .materials)
        try container.encode(styles, forKey: .styles)
        try container.encodeIfPresent(storageLocation, forKey: .storageLocation)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }
}

struct NewGarment: Encodable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    let wardrobeID: UUID
    let imagePath: String
    let name: String
    let category: YISUCategory
    let seasons: [String]
    let colors: [String]
    let brand: String?
    let price: Decimal?
    let size: String?
    let purchaseDate: Date?
    let materials: [String]
    let styles: [String]
    let storageLocation: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case wardrobeID = "wardrobe_id"
        case imagePath = "image_path"
        case name
        case category
        case seasons
        case colors
        case brand
        case price
        case size
        case purchaseDate = "purchase_date"
        case materials
        case styles
        case storageLocation = "storage_location"
        case notes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(wardrobeID, forKey: .wardrobeID)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(seasons, forKey: .seasons)
        try container.encode(colors, forKey: .colors)
        try container.encodeIfPresentOrNull(brand, forKey: .brand)
        try container.encodeIfPresentOrNull(price, forKey: .price)
        try container.encodeIfPresentOrNull(size, forKey: .size)
        try DateOnlyCoding.encodeIfPresentOrNull(purchaseDate, to: &container, forKey: .purchaseDate)
        try container.encode(materials, forKey: .materials)
        try container.encode(styles, forKey: .styles)
        try container.encodeIfPresentOrNull(storageLocation, forKey: .storageLocation)
        try container.encodeIfPresentOrNull(notes, forKey: .notes)
    }
}

enum NullableChange<Value: Encodable & Equatable & Sendable>: Equatable, Sendable {
    case value(Value)
    case clear
}

struct GarmentChanges: Encodable, Equatable, Sendable {
    var imagePath: String?
    var name: String?
    var category: YISUCategory?
    var seasons: [String]?
    var colors: [String]?
    var brand: NullableChange<String>?
    var price: NullableChange<Decimal>?
    var size: NullableChange<String>?
    var purchaseDate: NullableChange<Date>?
    var materials: [String]?
    var styles: [String]?
    var storageLocation: NullableChange<String>?
    var notes: NullableChange<String>?

    var isEmpty: Bool {
        imagePath == nil && name == nil && category == nil && seasons == nil && colors == nil &&
        brand == nil && price == nil && size == nil && purchaseDate == nil && materials == nil &&
        styles == nil && storageLocation == nil && notes == nil
    }

    init(
        imagePath: String? = nil,
        name: String? = nil,
        category: YISUCategory? = nil,
        seasons: [String]? = nil,
        colors: [String]? = nil,
        brand: NullableChange<String>? = nil,
        price: NullableChange<Decimal>? = nil,
        size: NullableChange<String>? = nil,
        purchaseDate: NullableChange<Date>? = nil,
        materials: [String]? = nil,
        styles: [String]? = nil,
        storageLocation: NullableChange<String>? = nil,
        notes: NullableChange<String>? = nil
    ) {
        self.imagePath = imagePath
        self.name = name
        self.category = category
        self.seasons = seasons
        self.colors = colors
        self.brand = brand
        self.price = price
        self.size = size
        self.purchaseDate = purchaseDate
        self.materials = materials
        self.styles = styles
        self.storageLocation = storageLocation
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case imagePath = "image_path"
        case name, category, seasons, colors, brand, price, size
        case purchaseDate = "purchase_date"
        case materials, styles
        case storageLocation = "storage_location"
        case notes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(seasons, forKey: .seasons)
        try container.encodeIfPresent(colors, forKey: .colors)
        try Self.encode(brand, to: &container, forKey: .brand)
        try Self.encode(price, to: &container, forKey: .price)
        try Self.encode(size, to: &container, forKey: .size)
        if let purchaseDate {
            switch purchaseDate {
            case .value(let date):
                try DateOnlyCoding.encodeIfPresent(date, to: &container, forKey: .purchaseDate)
            case .clear:
                try container.encodeNil(forKey: .purchaseDate)
            }
        }
        try container.encodeIfPresent(materials, forKey: .materials)
        try container.encodeIfPresent(styles, forKey: .styles)
        try Self.encode(storageLocation, to: &container, forKey: .storageLocation)
        try Self.encode(notes, to: &container, forKey: .notes)
    }

    private static func encode<Value: Encodable & Equatable & Sendable>(
        _ change: NullableChange<Value>?,
        to container: inout KeyedEncodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws {
        guard let change else { return }
        switch change {
        case .value(let value): try container.encode(value, forKey: key)
        case .clear: try container.encodeNil(forKey: key)
        }
    }
}

struct GarmentImage: Equatable, Sendable {
    let data: Data
    let pixelSize: CGSize

    static func objectPath(userID: UUID, garmentID: UUID) -> String {
        "\(userID.uuidString.lowercased())/\(garmentID.uuidString.lowercased())/original.jpg"
    }

    static func revisionPath(userID: UUID, garmentID: UUID, revisionID: UUID) -> String {
        "\(userID.uuidString.lowercased())/\(garmentID.uuidString.lowercased())/\(revisionID.uuidString.lowercased()).jpg"
    }
}

private enum DateOnlyCoding {
    static func decodeIfPresent<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Date? {
        guard let value = try container.decodeIfPresent(String.self, forKey: key) else { return nil }
        let components = value.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Expected a yyyy-MM-dd date"
            )
        }

        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let date = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: components[0],
            month: components[1],
            day: components[2]
        )) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Expected a valid yyyy-MM-dd date"
            )
        }
        return date
    }

    static func encodeIfPresent<Key: CodingKey>(
        _ date: Date?,
        to container: inout KeyedEncodingContainer<Key>,
        forKey key: Key
    ) throws {
        guard let date else { return }
        try container.encode(string(from: date), forKey: key)
    }

    static func encodeIfPresentOrNull<Key: CodingKey>(
        _ date: Date?,
        to container: inout KeyedEncodingContainer<Key>,
        forKey key: Key
    ) throws {
        guard let date else {
            try container.encodeNil(forKey: key)
            return
        }
        try container.encode(string(from: date), forKey: key)
    }

    private static func string(from date: Date) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeIfPresentOrNull<Value: Encodable>(_ value: Value?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }
}
