enum WardrobeSampleData {
    static let garments = [
        GarmentSummary(
            id: "white-linen-shirt",
            title: "白色亚麻衬衫",
            metadata: "春夏 · 上衣",
            imageName: "garment-white-linen-shirt",
            category: .tops
        ),
        GarmentSummary(
            id: "powder-blue-knit",
            title: "蓝色针织上衣",
            metadata: "春秋 · 上衣",
            imageName: "garment-powder-blue-knit",
            category: .tops
        ),
        GarmentSummary(
            id: "beige-trench",
            title: "米色风衣",
            metadata: "秋季 · 外套",
            imageName: "garment-beige-trench",
            category: .outerwear
        ),
        GarmentSummary(
            id: "black-knit-dress",
            title: "黑色针织连衣裙",
            metadata: "秋冬 · 裙子",
            imageName: "garment-black-knit-dress",
            category: .dresses
        )
    ]
}

enum WardrobeHomePolicy {
    static func items(_ items: [GarmentSummary], matching category: YISUCategory) -> [GarmentSummary] {
        category == .all ? items : items.filter { $0.category == category }
    }
}
