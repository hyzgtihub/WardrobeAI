import SwiftUI

enum YISUContentState: Equatable, Sendable {
    case content
    case empty
    case loading
    case error
    case noResults

    var allowsAction: Bool {
        switch self {
        case .empty, .error, .noResults: true
        case .content, .loading: false
        }
    }
}

struct YISUContentStateView: View {
    let state: YISUContentState
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: YISUTheme.Spacing.md) {
            stateGraphic

            Text(title)
                .font(YISUTheme.Typography.title)
                .foregroundStyle(YISUTheme.Color.textPrimary)

            Text(message)
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textSecondary)
                .multilineTextAlignment(.center)

            if state.allowsAction, let actionTitle, let action {
                YISUButton(
                    title: actionTitle,
                    style: .primary,
                    state: .normal,
                    accessibilityIdentifier: "designSystem.contentState.action",
                    action: action
                )
                .frame(maxWidth: 180)
            }
        }
        .padding(YISUTheme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(YISUTheme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("designSystem.contentState.\(identifierSuffix)")
    }

    @ViewBuilder
    private var stateGraphic: some View {
        if state == .loading {
            ProgressView()
                .controlSize(.large)
                .tint(YISUTheme.Color.brandEmphasis)
        } else {
            Image(systemName: symbolName)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(symbolColor)
                .frame(width: 56, height: 56)
                .background(symbolColor.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
    }

    private var symbolName: String {
        switch state {
        case .content: "checkmark"
        case .empty, .noResults: "plus"
        case .error: "exclamationmark"
        case .loading: "hourglass"
        }
    }

    private var symbolColor: Color {
        state == .error ? YISUTheme.Color.danger : YISUTheme.Color.brandEmphasis
    }

    private var identifierSuffix: String {
        switch state {
        case .content: "content"
        case .empty: "empty"
        case .loading: "loading"
        case .error: "error"
        case .noResults: "noResults"
        }
    }
}
