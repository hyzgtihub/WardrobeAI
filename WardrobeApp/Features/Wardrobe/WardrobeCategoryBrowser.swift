import SwiftUI

enum WardrobeCategorySelection {
    static func replacing(_ categories: Set<YISUCategory>, with category: YISUCategory?) -> Set<YISUCategory> {
        category.map { [$0] } ?? []
    }
}

struct WardrobeCategoryBrowser: View {
    let categories: Set<YISUCategory>
    let counts: [YISUCategory: Int]
    var accessibilityIdentifierPrefix = "wardrobe.category"
    let onSelect: (Set<YISUCategory>) -> Void

    private var allCount: Int {
        YISUCategory.browseableCases.reduce(0) { $0 + counts[$1, default: 0] }
    }

    private var multipleCount: Int {
        categories.reduce(0) { $0 + counts[$1, default: 0] }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: YISUTheme.Spacing.sm) {
                categoryControl(
                    title: "全部",
                    count: allCount,
                    isSelected: categories.isEmpty,
                    identifier: "\(accessibilityIdentifierPrefix).all"
                ) {
                    onSelect(WardrobeCategorySelection.replacing(categories, with: nil))
                }

                ForEach(YISUCategory.browseableCases, id: \.self) { category in
                    categoryControl(
                        title: category.title,
                        count: counts[category, default: 0],
                        isSelected: categories == [category],
                        identifier: "\(accessibilityIdentifierPrefix).\(category.rawValue)"
                    ) {
                        onSelect(WardrobeCategorySelection.replacing(categories, with: category))
                    }
                }

                if categories.count > 1 {
                    categoryControl(
                        title: "多分类",
                        count: multipleCount,
                        isSelected: true,
                        identifier: "\(accessibilityIdentifierPrefix).multiple"
                    ) {
                        onSelect(categories)
                    }
                }
            }
            .padding(.horizontal, YISUTheme.Spacing.sm)
        }
        .contentMargins(.vertical, YISUTheme.Spacing.sm, for: .scrollContent)
    }

    private func categoryControl(
        title: String,
        count: Int,
        isSelected: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: YISUTheme.Spacing.xs) {
                Text(title)
                Text("\(count)")
                    .foregroundStyle(isSelected ? YISUTheme.Color.textOnBrand.opacity(0.8) : YISUTheme.Color.textSecondary)
            }
            .font(YISUTheme.Typography.callout.weight(.semibold))
            .foregroundStyle(isSelected ? YISUTheme.Color.textOnBrand : YISUTheme.Color.textPrimary)
            .padding(.horizontal, YISUTheme.Spacing.md)
            .frame(minHeight: YISUTheme.Size.minimumTouchTarget)
            .background(isSelected ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.surface)
            .clipShape(Capsule())
            .overlay {
                if !isSelected {
                    Capsule().stroke(YISUTheme.Color.border, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Category Browser") {
    WardrobeCategoryBrowser(
        categories: [.tops, .pants],
        counts: [.tops: 4, .pants: 2, .dresses: 1],
        onSelect: { _ in }
    )
    .background(YISUTheme.Color.background)
}
