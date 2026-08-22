import SwiftUI

struct DesignSystemGalleryView: View {
    @State private var category: YISUCategory = .all
    @State private var tab: YISUTab = .wardrobe
    @State private var actionCount = 0

    private let garments = [
        GarmentSummary(id: "linen-shirt", title: "白色亚麻长袖衬衫轻薄通勤版型", metadata: "春夏 · 上衣", imageName: nil, category: .tops),
        GarmentSummary(id: "trench-coat", title: "米色短款风衣", metadata: "秋季 · 外套", imageName: nil, category: .outerwear)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.lg) {
                header
                buttonSection
                categorySection
                contentStateSection
                garmentSection
            }
            .padding(.horizontal, YISUTheme.Spacing.md)
            .padding(.top, YISUTheme.Spacing.md)
            .padding(.bottom, 104)
        }
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            YISUBottomNavigation(selection: tab) { tab = $0 }
                .padding(.horizontal, YISUTheme.Spacing.md)
                .padding(.bottom, YISUTheme.Spacing.sm)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
            Text("YISU Design System")
                .font(YISUTheme.Typography.title)
                .foregroundStyle(YISUTheme.Color.textPrimary)

            HStack {
                Text("分类：")
                Text(category.title)
                    .accessibilityIdentifier("designSystem.selection.category")
                Spacer()
                Text("底栏：")
                Text(tab.title)
                    .accessibilityIdentifier("designSystem.selection.tab")
                Text("操作：")
                Text("\(actionCount)")
                    .accessibilityIdentifier("designSystem.actionCount")
            }
            .font(YISUTheme.Typography.footnote)
            .foregroundStyle(YISUTheme.Color.textSecondary)
        }
    }

    private var buttonSection: some View {
        VStack(spacing: YISUTheme.Spacing.sm) {
            YISUButton(
                title: "主要操作",
                style: .primary,
                state: .normal,
                accessibilityIdentifier: "designSystem.button.primary"
            ) { actionCount += 1 }

            HStack(spacing: YISUTheme.Spacing.sm) {
                YISUButton(
                    title: "不可用",
                    style: .secondary,
                    state: .disabled,
                    accessibilityIdentifier: "designSystem.button.disabled"
                ) { actionCount += 1 }

                YISUButton(
                    title: "加载",
                    style: .primary,
                    state: .loading,
                    accessibilityIdentifier: "designSystem.button.loading"
                ) { actionCount += 1 }
            }
        }
    }

    private var categorySection: some View {
        YISUCategoryFilter(selection: category) { category = $0 }
            .padding(.horizontal, -YISUTheme.Spacing.sm)
    }

    private var contentStateSection: some View {
        YISUContentStateView(
            state: .empty,
            title: "还没有衣物",
            message: "添加第一件衣物，开始整理你的衣橱。",
            actionTitle: "添加衣物"
        ) { actionCount += 1 }
    }

    private var garmentSection: some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.md) {
            Text("衣物组件")
                .font(YISUTheme.Typography.headline)
                .foregroundStyle(YISUTheme.Color.textPrimary)

            YISUGarmentGrid(
                items: garments,
                stateForItem: { item in item.id == "trench-coat" ? .imageError : .normal },
                onSelect: { _ in actionCount += 1 }
            )
        }
    }
}

#Preview("Design System Gallery") {
    DesignSystemGalleryView()
}
