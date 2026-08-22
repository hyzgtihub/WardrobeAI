import SwiftUI

struct CurrentWardrobeView: View {
    let state: WardrobeSetupState
    let onRetry: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: YISUTheme.Spacing.lg) {
            switch state {
            case .loadingCurrentRole:
                YISUContentStateView(state: .loading, title: "正在确认身份", message: "请稍候…", actionTitle: nil, action: nil)
            case .currentRoleFailed:
                YISUContentStateView(state: .error, title: "暂时无法读取", message: "请重新尝试", actionTitle: "重试", action: onRetry)
            default:
                VStack(spacing: YISUTheme.Spacing.md) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 52))
                        .foregroundStyle(YISUTheme.Color.brandEmphasis)
                    Text("你是这个衣橱的主人")
                        .font(YISUTheme.Typography.title)
                    Text("可以添加、编辑和整理所有衣物")
                        .font(YISUTheme.Typography.callout)
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                }
                .padding(YISUTheme.Spacing.lg)
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(YISUTheme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
                YISUButton(title: "进入衣橱", style: .primary, state: .normal, accessibilityIdentifier: "onboarding.enterWardrobe", action: onContinue)
            }
        }
    }
}

#Preview("身份已确认") { CurrentWardrobeView(state: .currentRole, onRetry: {}, onContinue: {}) }
#Preview("身份载入") { CurrentWardrobeView(state: .loadingCurrentRole, onRetry: {}, onContinue: {}) }
#Preview("身份失败") { CurrentWardrobeView(state: .currentRoleFailed, onRetry: {}, onContinue: {}) }
