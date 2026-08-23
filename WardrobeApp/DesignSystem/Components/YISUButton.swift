import SwiftUI

enum YISUButtonStyle: Equatable, Sendable {
    case primary
    case secondary
}

enum YISUButtonPolicy {
    static func canSendAction(in state: YISUControlState) -> Bool {
        state.isInteractive
    }
}

struct YISUButton: View {
    let title: String
    let style: YISUButtonStyle
    let state: YISUControlState
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button {
            guard YISUButtonPolicy.canSendAction(in: state) else { return }
            action()
        } label: {
            HStack(spacing: YISUTheme.Spacing.sm) {
                if state == .loading {
                    ProgressView()
                        .tint(foregroundColor)
                        .accessibilityHidden(true)
                }

                Text(state == .loading ? "处理中…" : title)
                    .font(YISUTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: YISUTheme.Size.buttonHeight)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.medium))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: YISUTheme.Radius.medium)
                        .stroke(YISUTheme.Color.border, lineWidth: 1)
                }
            }
            .opacity(state == .disabled ? 0.45 : 1)
            .scaleEffect(state == .pressed ? 0.98 : 1)
        }
        .buttonStyle(YISUPressButtonStyle())
        .disabled(!YISUButtonPolicy.canSendAction(in: state))
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(state == .loading ? "\(title)，处理中" : title)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: YISUTheme.Color.brandEmphasis
        case .secondary: YISUTheme.Color.surface
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: YISUTheme.Color.textOnBrand
        case .secondary: YISUTheme.Color.textPrimary
        }
    }
}

private struct YISUPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Button States") {
    VStack(spacing: YISUTheme.Spacing.md) {
        YISUButton(title: "添加衣物", style: .primary, state: .normal, accessibilityIdentifier: "preview.primary") {}
        YISUButton(title: "取消", style: .secondary, state: .disabled, accessibilityIdentifier: "preview.disabled") {}
        YISUButton(title: "保存", style: .primary, state: .loading, accessibilityIdentifier: "preview.loading") {}
    }
    .padding()
    .background(YISUTheme.Color.background)
}
