import SwiftUI

struct YISUCategoryChip: View {
    let category: YISUCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.title)
                .font(YISUTheme.Typography.callout.weight(.semibold))
                .foregroundStyle(isSelected ? YISUTheme.Color.textOnBrand : YISUTheme.Color.textPrimary)
                .padding(.horizontal, YISUTheme.Spacing.md)
                .frame(minWidth: 64, minHeight: YISUTheme.Size.minimumTouchTarget)
                .background(isSelected ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.surface)
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule().stroke(YISUTheme.Color.border, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(category.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

enum YISUCategorySelection {
    static func select(_ category: YISUCategory, current: YISUCategory) -> YISUCategory {
        category
    }
}
