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
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                        onSelect(tab)
                    }
                } label: {
                    tabContent(tab)
                    .frame(maxWidth: .infinity, minHeight: YISUTheme.Size.bottomNavigationHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(YISUNavPressStyle())
                .accessibilityLabel(tab.title)
                .accessibilityIdentifier(tab.accessibilityIdentifier)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, YISUTheme.Spacing.sm)
        .padding(.vertical, YISUTheme.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(YISUTheme.Color.surface.opacity(0.98))
                .shadow(color: YISUTheme.Shadow.color, radius: YISUTheme.Shadow.radius, y: YISUTheme.Shadow.y)
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: selection)
    }

    @ViewBuilder
    private func tabContent(_ tab: YISUTab) -> some View {
        if tab == .addGarment {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(YISUTheme.Color.brand)
                        .frame(width: 64, height: 64)
                        .overlay {
                            Circle()
                                .stroke(YISUTheme.Color.surface, lineWidth: 8)
                        }
                        .shadow(color: YISUTheme.Shadow.color, radius: 12, y: 5)

                    YISUTabGlyph(tab: tab, selected: true, tint: YISUTheme.Color.textOnBrand)
                        .frame(width: 27, height: 27)
                }
                .offset(y: -18)
                .frame(height: 46)

                Text(tab.title)
                    .font(YISUTheme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(YISUTheme.Color.brandEmphasis)
                    .lineLimit(1)
            }
        } else {
            let isSelected = selection == tab
            VStack(spacing: YISUTheme.Spacing.xxs) {
                ZStack {
                    Circle()
                        .fill(YISUTheme.Color.brandSubtle)
                        .frame(width: 48, height: 48)
                        .scaleEffect(isSelected ? 1 : 0.82)
                        .opacity(isSelected ? 1 : 0)

                    YISUTabGlyph(
                        tab: tab,
                        selected: isSelected,
                        tint: isSelected ? YISUTheme.Color.navAccent : YISUTheme.Color.textSecondary
                    )
                    .frame(width: 24, height: 24)
                }
                .frame(height: 48)

                Text(tab.title)
                    .font(YISUTheme.Typography.footnote.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct YISUTabGlyph: View {
    let tab: YISUTab
    let selected: Bool
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let style = StrokeStyle(
                lineWidth: selected ? 2 : 1.75,
                lineCap: .round,
                lineJoin: .round
            )
            context.stroke(path(in: size), with: .color(tint), style: style)

            if tab == .profile && selected {
                context.fill(profileHead(in: size), with: .color(YISUTheme.Color.brandSubtle))
                context.stroke(profileHead(in: size), with: .color(tint), style: style)
            }
        }
        .accessibilityHidden(true)
    }

    private func path(in size: CGSize) -> Path {
        let scale = min(size.width, size.height) / 24
        var path = Path()

        switch tab {
        case .wardrobe:
            path.addRoundedRect(
                in: CGRect(x: 1, y: 1.5, width: 22, height: 19.5),
                cornerSize: CGSize(width: 2.5, height: 2.5)
            )
            path.move(to: CGPoint(x: 12, y: 1.5))
            path.addLine(to: CGPoint(x: 12, y: 21))
            path.move(to: CGPoint(x: 5.5, y: 8))
            path.addLine(to: CGPoint(x: 7.25, y: 8))
            path.move(to: CGPoint(x: 16.75, y: 8))
            path.addLine(to: CGPoint(x: 18.5, y: 8))
            path.move(to: CGPoint(x: 6.5, y: selected ? 16.5 : 17.5))
            path.addCurve(
                to: CGPoint(x: 17.5, y: selected ? 16.5 : 17.5),
                control1: CGPoint(x: 9.5, y: selected ? 14 : 20.5),
                control2: CGPoint(x: 14.5, y: selected ? 14 : 20.5)
            )
        case .addGarment:
            path.move(to: CGPoint(x: 9, y: 4))
            path.addLine(to: CGPoint(x: 4, y: 7))
            path.addLine(to: CGPoint(x: 6, y: 11))
            path.addLine(to: CGPoint(x: 8, y: 10))
            path.addLine(to: CGPoint(x: 8, y: 21))
            path.addLine(to: CGPoint(x: 16, y: 21))
            path.addLine(to: CGPoint(x: 16, y: 10))
            path.addLine(to: CGPoint(x: 18, y: 11))
            path.addLine(to: CGPoint(x: 20, y: 7))
            path.addLine(to: CGPoint(x: 15, y: 4))
            path.addCurve(to: CGPoint(x: 9, y: 4), control1: CGPoint(x: 13, y: 6), control2: CGPoint(x: 11, y: 6))
            if selected {
                path.move(to: CGPoint(x: 19, y: 14))
                path.addLine(to: CGPoint(x: 19, y: 20))
                path.move(to: CGPoint(x: 16, y: 17))
                path.addLine(to: CGPoint(x: 22, y: 17))
            }
        case .profile:
            path.addPath(profileHead(in: size))
            path.move(to: CGPoint(x: 3, y: 22))
            path.addCurve(
                to: CGPoint(x: 21, y: 22),
                control1: CGPoint(x: 3.75, y: 14.8),
                control2: CGPoint(x: 20.25, y: 15.8)
            )
        }

        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }

    private func profileHead(in size: CGSize) -> Path {
        let scale = min(size.width, size.height) / 24
        return Path(ellipseIn: CGRect(x: 7.75, y: 2.75, width: 8.5, height: 8.5))
            .applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

private struct YISUNavPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Bottom Navigation") {
    YISUBottomNavigation(selection: .wardrobe) { _ in }
        .padding()
        .background(YISUTheme.Color.background)
}
