import SwiftUI

struct YISUGarmentGrid: View {
    let items: [GarmentSummary]
    let stateForItem: (GarmentSummary) -> YISUGarmentCardState
    let imageRepository: (any GarmentImageRepository)?
    let onSelect: (GarmentSummary) -> Void

    init(
        items: [GarmentSummary],
        stateForItem: @escaping (GarmentSummary) -> YISUGarmentCardState,
        imageRepository: (any GarmentImageRepository)? = nil,
        onSelect: @escaping (GarmentSummary) -> Void
    ) {
        self.items = items
        self.stateForItem = stateForItem
        self.imageRepository = imageRepository
        self.onSelect = onSelect
    }

    private let columns = [
        GridItem(.flexible(), spacing: YISUTheme.Spacing.md),
        GridItem(.flexible(), spacing: YISUTheme.Spacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: YISUTheme.Spacing.md) {
            ForEach(items) { item in
                YISUGarmentCard(
                    item: item,
                    state: stateForItem(item),
                    imageRepository: imageRepository,
                    onSelect: onSelect
                )
            }
        }
        .accessibilityIdentifier("designSystem.garmentGrid")
    }
}

#Preview("Garment Grid") {
    YISUGarmentGrid(
        items: [
            GarmentSummary(id: UUID(uuidString: "33333333-3333-3333-3333-333333333301")!, title: "白色亚麻长袖衬衫轻薄通勤版型", metadata: "春夏 · 上衣", imagePath: nil, category: .tops),
            GarmentSummary(id: UUID(uuidString: "33333333-3333-3333-3333-333333333302")!, title: "米色短款风衣", metadata: "秋季 · 外套", imagePath: nil, category: .outerwear)
        ],
        stateForItem: { _ in .normal },
        onSelect: { _ in }
    )
    .padding()
    .background(YISUTheme.Color.background)
}
