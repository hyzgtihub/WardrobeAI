import Foundation

enum WardrobeSampleData {
    static let garments = [
        GarmentSummary(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111101")!,
            title: "白色亚麻衬衫",
            metadata: "春夏 · 上衣",
            imagePath: "garment-white-linen-shirt",
            category: .tops
        ),
        GarmentSummary(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111102")!,
            title: "蓝色针织上衣",
            metadata: "春秋 · 上衣",
            imagePath: "garment-powder-blue-knit",
            category: .tops
        ),
        GarmentSummary(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111103")!,
            title: "米色风衣",
            metadata: "秋季 · 外套",
            imagePath: "garment-beige-trench",
            category: .outerwear
        ),
        GarmentSummary(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111104")!,
            title: "黑色针织连衣裙",
            metadata: "秋冬 · 裙子",
            imagePath: "garment-black-knit-dress",
            category: .dresses
        )
    ]
}

enum WardrobeHomePolicy {
    static func items(_ items: [GarmentSummary], matching category: YISUCategory) -> [GarmentSummary] {
        category == .all ? items : items.filter { $0.category == category }
    }
}
