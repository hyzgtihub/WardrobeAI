import Foundation

struct GarmentDetailDraft: Equatable, Sendable {
    let id: UUID
    var name: String
    var subtitle: String
    var imageName: String
    var category: YISUCategory
    var seasons: [String]
    var storageLocation: String
    var notes: String
    var colors: [String]
    var brand: String
    var price: String
    var size: String
    var purchaseDate: String
    var materials: [String]
    var styles: [String]

    var imagePath: String { imageName }

    init(
        id: UUID,
        name: String,
        subtitle: String,
        imageName: String,
        category: YISUCategory,
        seasons: [String],
        storageLocation: String,
        notes: String,
        colors: [String],
        brand: String,
        price: String,
        size: String,
        purchaseDate: String,
        materials: [String],
        styles: [String]
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.imageName = imageName
        self.category = category
        self.seasons = seasons
        self.storageLocation = storageLocation
        self.notes = notes
        self.colors = colors
        self.brand = brand
        self.price = price
        self.size = size
        self.purchaseDate = purchaseDate
        self.materials = materials
        self.styles = styles
    }

    init(garment: Garment) {
        id = garment.id
        name = garment.name
        subtitle = garment.brand ?? garment.category.title
        imageName = garment.imagePath
        category = garment.category
        seasons = garment.seasons
        storageLocation = garment.storageLocation ?? ""
        notes = garment.notes ?? ""
        colors = garment.colors
        brand = garment.brand ?? ""
        price = Self.priceText(garment.price)
        size = garment.size ?? ""
        purchaseDate = garment.purchaseDate.map { Self.dateFormatter.string(from: $0) } ?? ""
        materials = garment.material.map { [$0] } ?? []
        styles = garment.style.map { [$0] } ?? []
    }

    static let whiteLinenShirt = GarmentDetailDraft(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111101")!,
        name: "白色亚麻衬衫",
        subtitle: "柔软亚麻 · 适合春夏通勤",
        imageName: "garment-white-linen-shirt",
        category: .tops,
        seasons: ["春季", "夏季"],
        storageLocation: "主卧衣橱 · 上层",
        notes: "适合搭配浅色长裤",
        colors: ["白色"],
        brand: "MUJI",
        price: "¥299",
        size: "M",
        purchaseDate: "2026.04.18",
        materials: ["亚麻", "棉"],
        styles: ["通勤", "简约"]
    )

    var summary: GarmentSummary {
        GarmentSummary(
            id: id,
            title: name,
            metadata: "\(seasons.map { String($0.prefix(1)) }.joined()) · \(category.title)",
            imagePath: imageName,
            category: category
        )
    }

    private static func priceText(_ price: Decimal?) -> String {
        guard let price else { return "" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "¥\(formatter.string(from: price as NSDecimalNumber) ?? "")"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

extension Garment {
    var summary: GarmentSummary {
        GarmentSummary(
            id: id,
            title: name,
            metadata: "\(seasons.joined(separator: "、")) · \(category.title)",
            imagePath: imagePath,
            category: category
        )
    }
}

enum GarmentDetailIssue: Equatable, Sendable {
    case nameRequired
    case seasonRequired
}

enum GarmentDetailPolicy {
    static let textDebounceNanoseconds: UInt64 = 800_000_000

    static func issue(for draft: GarmentDetailDraft) -> GarmentDetailIssue? {
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .nameRequired }
        if draft.seasons.isEmpty { return .seasonRequired }
        return nil
    }
}

enum GarmentAutosaveState: Equatable, Sendable {
    case idle, pending, saving, saved, failed, offline, photoFailed, loadingFailed

    var message: String {
        switch self {
        case .idle: ""
        case .pending: "等待保存"
        case .saving: "正在保存"
        case .saved: "已保存"
        case .failed: "保存失败，请重试"
        case .offline: "已离线，恢复网络后将自动保存"
        case .photoFailed: "图片更新失败"
        case .loadingFailed: "衣物信息加载失败"
        }
    }
}
