import Foundation

enum AddGarmentIssue: Equatable, Sendable {
    case photoRequired
    case nameRequired
    case categoryRequired
    case seasonRequired
    case invalidPrice
}

enum AddGarmentState: Equatable, Sendable {
    case idle
    case processingPhoto
    case editing
    case validating
    case uploadingPhoto
    case creatingGarment
    case succeeded
    case photoProcessingFailed
    case uploadFailed
    case createFailed
}

struct AddGarmentDraft: Equatable, Sendable {
    var photo: GarmentImage?
    var name: String
    var category: YISUCategory?
    var seasons: [String]
    var colors: [String]
    var brand: String
    var price: String
    var size: String
    var purchaseDate: Date?
    var material: String
    var style: String
    var storageLocation: String
    var notes: String

    init(
        photo: GarmentImage? = nil,
        name: String = "",
        category: YISUCategory? = nil,
        seasons: [String] = [],
        colors: [String] = [],
        brand: String = "",
        price: String = "",
        size: String = "",
        purchaseDate: Date? = nil,
        material: String = "",
        style: String = "",
        storageLocation: String = "",
        notes: String = ""
    ) {
        self.photo = photo
        self.name = name
        self.category = category
        self.seasons = seasons
        self.colors = colors
        self.brand = brand
        self.price = price
        self.size = size
        self.purchaseDate = purchaseDate
        self.material = material
        self.style = style
        self.storageLocation = storageLocation
        self.notes = notes
    }
}
