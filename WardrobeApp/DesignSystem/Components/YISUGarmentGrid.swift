import SwiftUI

struct YISUGarmentGrid: View {
    let items: [GarmentSummary]
    let stateForItem: (GarmentSummary) -> YISUGarmentCardState
    let onSelect: (GarmentSummary) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: YISUTheme.Spacing.md),
        GridItem(.flexible(), spacing: YISUTheme.Spacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: YISUTheme.Spacing.md) {
            ForEach(items) { item in
                YISUGarmentCard(item: item, state: stateForItem(item), onSelect: onSelect)
            }
        }
        .accessibilityIdentifier("designSystem.garmentGrid")
    }
}

#Preview("Garment Grid") {
    YISUGarmentGrid(
        items: [
            GarmentSummary(id: "shirt", title: "白色亚麻长袖衬衫轻薄通勤版型", metadata: "春夏 · 上衣", imageName: nil),
            GarmentSummary(id: "coat", title: "米色短款风衣", metadata: "秋季 · 外套", imageName: nil)
        ],
        stateForItem: { _ in .normal },
        onSelect: { _ in }
    )
    .padding()
    .background(YISUTheme.Color.background)
}
