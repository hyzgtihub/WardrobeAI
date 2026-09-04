import SwiftUI

struct WardrobeHomeView: View {
    let items: [GarmentSummary]
    let state: GarmentStore.State
    let imageRepository: (any GarmentImageRepository)?
    let onSearch: () -> Void
    let onAdd: () -> Void
    let onSelectGarment: (GarmentSummary) -> Void
    let onProfile: () -> Void

    @State private var category: YISUCategory = .all

    init(
        items: [GarmentSummary] = WardrobeSampleData.garments,
        state: GarmentStore.State = .loaded,
        imageRepository: (any GarmentImageRepository)? = nil,
        onSearch: @escaping () -> Void = {},
        onAdd: @escaping () -> Void = {},
        onSelectGarment: @escaping (GarmentSummary) -> Void = { _ in },
        onProfile: @escaping () -> Void = {}
    ) {
        self.items = items
        self.state = state
        self.imageRepository = imageRepository
        self.onSearch = onSearch
        self.onAdd = onAdd
        self.onSelectGarment = onSelectGarment
        self.onProfile = onProfile
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.lg) {
                header
                YISUCategoryFilter(selection: category) { category = $0 }
                    .padding(.horizontal, -YISUTheme.Spacing.sm)
                content
            }
            .padding(.horizontal, YISUTheme.Spacing.md)
            .padding(.top, YISUTheme.Spacing.md)
            .padding(.bottom, YISUTheme.Spacing.lg)
        }
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            YISUBottomNavigation(selection: .wardrobe) { tab in
                switch tab {
                case .wardrobe: break
                case .addGarment: onAdd()
                case .profile: onProfile()
                }
            }
            .padding(.horizontal, YISUTheme.Spacing.md)
            .padding(.bottom, YISUTheme.Spacing.sm)
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
                Text("我的衣橱")
                    .font(YISUTheme.Typography.largeTitle)
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                    .accessibilityIdentifier("wardrobe.title")
                Text("今天想穿什么？")
                    .font(YISUTheme.Typography.callout)
                    .foregroundStyle(YISUTheme.Color.textSecondary)
            }
            Spacer()
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(YISUTheme.Color.brandEmphasis)
            .accessibilityLabel("搜索衣物")
            .accessibilityIdentifier("wardrobe.search")
        }
    }

    @ViewBuilder private var content: some View {
        if state == .loading || state == .idle {
            YISUContentStateView(state: .loading, title: "正在载入衣橱", message: "请稍候…", actionTitle: nil, action: nil)
        } else if state == .failed {
            YISUContentStateView(state: .error, title: "无法载入衣橱", message: "请检查网络后重试。", actionTitle: nil, action: nil)
        } else if filteredItems.isEmpty {
            YISUContentStateView(
                state: .noResults,
                title: "还没有这类衣物",
                message: "可以添加一件，或切换其他分类。",
                actionTitle: "添加衣物",
                action: onAdd,
                actionAccessibilityIdentifier: "wardrobe.empty.add"
            )
        } else {
            YISUGarmentGrid(
                items: filteredItems,
                stateForItem: { _ in .normal },
                imageRepository: imageRepository,
                onSelect: onSelectGarment
            )
        }
    }

    private var filteredItems: [GarmentSummary] {
        WardrobeHomePolicy.items(items, matching: category)
    }
}

#Preview("P05 · 衣橱首页") { WardrobeHomeView() }
