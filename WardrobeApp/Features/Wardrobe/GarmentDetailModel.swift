import Foundation

struct GarmentDetailDraft: Equatable, Sendable {
    let id: String
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

    static let whiteLinenShirt = GarmentDetailDraft(
        id: "white-linen-shirt",
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
            imageName: imageName,
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
