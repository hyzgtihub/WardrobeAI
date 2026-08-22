import SwiftUI

enum YISUTab: String, CaseIterable, Equatable, Sendable {
    case wardrobe
    case addGarment
    case profile

    var title: String {
        switch self {
        case .wardrobe: "衣橱"
        case .addGarment: "添加衣物"
        case .profile: "我的"
        }
    }

    var symbolName: String {
        switch self {
        case .wardrobe: "square.grid.2x2"
        case .addGarment: "plus"
        case .profile: "person"
        }
    }

    var accessibilityIdentifier: String {
        "designSystem.tab.\(rawValue)"
    }
}

struct YISUBottomNavigation: View {
    let selection: YISUTab
    let onSelect: (YISUTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(YISUTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: YISUTheme.Spacing.xs) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: tab == .addGarment ? 22 : 20, weight: .semibold))
                            .frame(width: YISUTheme.Size.minimumTouchTarget, height: 28)

                        Text(tab.title)
                            .font(YISUTheme.Typography.footnote)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == tab ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: YISUTheme.Size.bottomNavigationHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(tab.accessibilityIdentifier)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, YISUTheme.Spacing.sm)
        .background(YISUTheme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
        .shadow(color: YISUTheme.Shadow.color, radius: YISUTheme.Shadow.radius, y: YISUTheme.Shadow.y)
        .accessibilityIdentifier("designSystem.bottomNavigation")
    }
}

#Preview("Bottom Navigation") {
    YISUBottomNavigation(selection: .wardrobe) { _ in }
        .padding()
        .background(YISUTheme.Color.background)
}
