import SwiftUI

struct YISUCategoryFilter: View {
    let selection: YISUCategory
    let onSelect: (YISUCategory) -> Void

    private var selectedCategories: Set<YISUCategory> {
        selection == .all ? [] : [selection]
    }

    var body: some View {
        WardrobeCategoryBrowser(
            categories: selectedCategories,
            counts: [:],
            accessibilityIdentifierPrefix: "designSystem.category"
        ) { categories in
            onSelect(categories.first ?? .all)
        }
        .accessibilityIdentifier("designSystem.categoryFilter")
    }
}

#Preview("Category Filter") {
    YISUCategoryFilter(selection: .tops) { _ in }
        .background(YISUTheme.Color.background)
}
