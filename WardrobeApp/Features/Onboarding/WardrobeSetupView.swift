import SwiftUI

struct WardrobeSetupView: View {
    let state: WardrobeSetupState
    let onRetry: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: YISUTheme.Spacing.lg) {
            Spacer()
            Text("建立你的数字衣橱")
                .font(YISUTheme.Typography.largeTitle)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("衣序会为你准备一个安全、专属的衣橱空间")
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textSecondary)
                .multilineTextAlignment(.center)

            stateCard
            Spacer()
        }
        .padding(YISUTheme.Spacing.lg)
        .background(YISUTheme.Color.background.ignoresSafeArea())
    }

    @ViewBuilder private var stateCard: some View {
        switch state {
        case .creating:
            YISUContentStateView(state: .loading, title: "正在创建衣橱", message: "请稍候…", actionTitle: nil, action: nil)
        case .creationFailed:
            YISUContentStateView(
                state: .error,
                title: "创建失败",
                message: "网络开了个小差，请重试",
                actionTitle: "重试",
                action: onRetry,
                actionAccessibilityIdentifier: "onboarding.retry"
            )
        case .created:
            YISUContentStateView(state: .content, title: "衣橱已准备好", message: "接下来确认你在衣橱中的身份", actionTitle: nil, action: nil)
            YISUButton(title: "继续", style: .primary, state: .normal, accessibilityIdentifier: "onboarding.continue", action: onContinue)
        case .currentRole, .loadingCurrentRole, .currentRoleFailed:
            CurrentWardrobeView(state: state, onRetry: onRetry, onContinue: onContinue)
        }
    }
}

#Preview("创建中") { WardrobeSetupView(state: .creating, onRetry: {}, onContinue: {}) }
#Preview("创建失败") { WardrobeSetupView(state: .creationFailed, onRetry: {}, onContinue: {}) }
#Preview("创建成功") { WardrobeSetupView(state: .created, onRetry: {}, onContinue: {}) }
