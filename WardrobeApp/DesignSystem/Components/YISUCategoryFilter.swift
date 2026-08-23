import SwiftUI

struct YISUCategoryFilter: View {
    let selection: YISUCategory
    let onSelect: (YISUCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: YISUTheme.Spacing.sm) {
                ForEach(YISUCategory.allCases, id: \.self) { category in
                    YISUCategoryChip(category: category, isSelected: category == selection) {
                        onSelect(YISUCategorySelection.select(category, current: selection))
                    }
                }
            }
            .padding(.horizontal, YISUTheme.Spacing.sm)
        }
        .contentMargins(.vertical, YISUTheme.Spacing.sm, for: .scrollContent)
        .accessibilityIdentifier("designSystem.categoryFilter")
    }
}

#Preview("Category Filter") {
    YISUCategoryFilter(selection: .tops) { _ in }
        .background(YISUTheme.Color.background)
}
