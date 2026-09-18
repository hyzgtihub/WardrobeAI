import SwiftUI

struct WardrobeHomeView: View {
    let garments: [Garment]
    @Binding var filter: WardrobeFilter
    let state: GarmentStore.State
    let imageRepository: (any GarmentImageRepository)?
    let onAdd: () -> Void
    let onSelectGarment: (GarmentSummary) -> Void
    let onProfile: () -> Void

    @State private var isFilterPresented = false

    init(
        garments: [Garment],
        filter: Binding<WardrobeFilter>,
        state: GarmentStore.State = .loaded,
        imageRepository: (any GarmentImageRepository)? = nil,
        onAdd: @escaping () -> Void = {},
        onSelectGarment: @escaping (GarmentSummary) -> Void = { _ in },
        onProfile: @escaping () -> Void = {}
    ) {
        self.garments = garments
        _filter = filter
        self.state = state
        self.imageRepository = imageRepository
        self.onAdd = onAdd
        self.onSelectGarment = onSelectGarment
        self.onProfile = onProfile
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.lg) {
                header
                filterControls
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
        .sheet(isPresented: $isFilterPresented) {
            WardrobeFilterSheet(
                appliedFilter: filter,
                garments: garments,
                onApply: { appliedFilter in
                    filter = appliedFilter
                    isFilterPresented = false
                },
                onCancel: {
                    isFilterPresented = false
                }
            )
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
            Text("我的衣橱")
                .font(YISUTheme.Typography.largeTitle)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .accessibilityIdentifier("wardrobe.title")
            Text("今天想穿什么？")
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textSecondary)
        }
    }

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.sm) {
            WardrobeFilterBar(
                filter: filter,
                onOpen: { isFilterPresented = true },
                onRemove: removeFilter
            )

            WardrobeCategoryBrowser(
                categories: filter.categories,
                onSelect: { filter.categories = $0 }
            )
            .padding(.horizontal, -YISUTheme.Spacing.sm)
        }
    }

    @ViewBuilder private var content: some View {
        if state == .loading || state == .idle {
            YISUContentStateView(
                state: .loading,
                title: "正在载入衣橱",
                message: "请稍候…",
                actionTitle: nil,
                action: nil
            )
        } else if state == .failed {
            YISUContentStateView(
                state: .error,
                title: "无法载入衣橱",
                message: "请检查网络后重试。",
                actionTitle: nil,
                action: nil
            )
        } else if garments.isEmpty {
            YISUContentStateView(
                state: .empty,
                title: "衣橱还是空的",
                message: "添加第一件衣物，开始整理你的衣橱。",
                actionTitle: "添加第一件衣物",
                action: onAdd,
                actionAccessibilityIdentifier: "wardrobe.empty.add"
            )
        } else if filteredGarments.isEmpty {
            noFilterResults
        } else {
            YISUGarmentGrid(
                items: filteredGarments.map(\.summary),
                stateForItem: { _ in .normal },
                imageRepository: imageRepository,
                onSelect: onSelectGarment
            )
        }
    }

    private var noFilterResults: some View {
        VStack(spacing: YISUTheme.Spacing.md) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(YISUTheme.Color.brandEmphasis)
                .frame(width: 56, height: 56)
                .background(YISUTheme.Color.brandEmphasis.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text("没有符合条件的衣物")
                .font(YISUTheme.Typography.title)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("可以清空筛选，或添加一件新衣物。")
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: YISUTheme.Spacing.sm) {
                YISUButton(
                    title: "清空筛选",
                    style: .primary,
                    state: .normal,
                    accessibilityIdentifier: "wardrobe.filter.clearAll",
                    action: { filter = WardrobeFilter() }
                )
                YISUButton(
                    title: "添加衣物",
                    style: .secondary,
                    state: .normal,
                    accessibilityIdentifier: "wardrobe.filteredEmpty.add",
                    action: onAdd
                )
            }
            .frame(maxWidth: 240)
        }
        .padding(YISUTheme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(YISUTheme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wardrobe.filteredEmpty")
    }

    private var filteredGarments: [Garment] {
        WardrobeFilterPolicy.filteredGarments(garments, by: filter)
    }

    private func removeFilter(_ dimension: WardrobeFilterDimension, value: String) {
        switch dimension {
        case .category:
            break
        case .season:
            filter.seasons.remove(value)
        case .color:
            filter.colors.remove(value)
        case .material:
            filter.materials.remove(value)
        case .style:
            filter.styles.remove(value)
        case .size:
            filter.sizes.remove(value)
        case .storageLocation:
            filter.storageLocations.remove(value)
        }
    }
}

private enum WardrobeHomePreview {
    static let garments: [Garment] = [
        garment(
            id: "11111111-1111-1111-1111-111111111101",
            name: "白色亚麻衬衫",
            imagePath: "garment-white-linen-shirt",
            category: .tops,
            seasons: ["春季", "夏季"]
        ),
        garment(
            id: "11111111-1111-1111-1111-111111111103",
            name: "米色风衣",
            imagePath: "garment-beige-trench",
            category: .outerwear,
            seasons: ["秋季"]
        )
    ]

    private static func garment(
        id: String,
        name: String,
        imagePath: String,
        category: YISUCategory,
        seasons: [String]
    ) -> Garment {
        Garment(
            id: UUID(uuidString: id)!,
            userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            wardrobeID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            imagePath: imagePath,
            name: name,
            category: category,
            seasons: seasons,
            colors: [],
            brand: nil,
            price: nil,
            size: nil,
            purchaseDate: nil,
            materials: [],
            styles: [],
            storageLocation: nil,
            notes: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deletedAt: nil
        )
    }
}

#Preview("P05 · 衣橱首页") {
    WardrobeHomeView(
        garments: WardrobeHomePreview.garments,
        filter: .constant(WardrobeFilter())
    )
}
