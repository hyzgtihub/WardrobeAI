import SwiftUI

struct WardrobeFilterDraft: Equatable {
    private(set) var filter: WardrobeFilter

    init(_ appliedFilter: WardrobeFilter) {
        filter = appliedFilter
    }

    mutating func reset() {
        filter = WardrobeFilter()
    }

    mutating func toggle(_ value: String, in dimension: WardrobeFilterDimension) {
        switch dimension {
        case .category:
            guard let category = YISUCategory.browseableCases.first(where: { $0.title == value }) else { return }
            Self.toggle(category, in: &filter.categories)
        case .season:
            Self.toggle(value, in: &filter.seasons)
        case .color:
            Self.toggle(value, in: &filter.colors)
        case .material:
            Self.toggle(value, in: &filter.materials)
        case .style:
            Self.toggle(value, in: &filter.styles)
        case .size:
            Self.toggle(value, in: &filter.sizes)
        case .storageLocation:
            Self.toggle(value, in: &filter.storageLocations)
        }
    }

    private static func toggle(_ category: YISUCategory, in values: inout Set<YISUCategory>) {
        if values.contains(category) {
            values.remove(category)
        } else {
            values.insert(category)
        }
    }

    private static func toggle(_ value: String, in values: inout Set<String>) {
        if let existing = values.first(where: { WardrobeFilterPolicy.normalized($0) == WardrobeFilterPolicy.normalized(value) }) {
            values.remove(existing)
        } else {
            values.insert(value)
        }
    }
}

struct WardrobeFilterSheet: View {
    let appliedFilter: WardrobeFilter
    let garments: [Garment]
    let onApply: (WardrobeFilter) -> Void
    let onCancel: () -> Void

    @State private var draft: WardrobeFilterDraft
    @State private var expandedDimensions: Set<WardrobeFilterDimension> = []
    @State private var didFinish = false

    init(
        appliedFilter: WardrobeFilter,
        garments: [Garment],
        onApply: @escaping (WardrobeFilter) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.appliedFilter = appliedFilter
        self.garments = garments
        self.onApply = onApply
        self.onCancel = onCancel
        _draft = State(initialValue: WardrobeFilterDraft(appliedFilter))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: YISUTheme.Spacing.md) {
                    ForEach(WardrobeFilterDimension.allCases) { dimension in
                        dimensionSection(dimension)
                    }
                }
                .padding(.horizontal, YISUTheme.Spacing.md)
                .padding(.vertical, YISUTheme.Spacing.lg)
            }
        }
        .background(YISUTheme.Color.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wardrobe.filter.sheet")
        .onDisappear {
            if !didFinish {
                onCancel()
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: cancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                    .frame(width: YISUTheme.Size.minimumTouchTarget, height: YISUTheme.Size.minimumTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭筛选")
            .accessibilityIdentifier("wardrobe.filter.close")

            Spacer()
            Text("筛选")
                .font(YISUTheme.Typography.headline)
                .foregroundStyle(YISUTheme.Color.textPrimary)
            Spacer()

            Color.clear
                .frame(width: YISUTheme.Size.minimumTouchTarget, height: YISUTheme.Size.minimumTouchTarget)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, YISUTheme.Spacing.md)
        .padding(.vertical, YISUTheme.Spacing.sm)
        .background(YISUTheme.Color.surface)
    }

    private var actionBar: some View {
        HStack(spacing: YISUTheme.Spacing.md) {
            Button("重置") {
                draft.reset()
            }
            .buttonStyle(.bordered)
            .tint(YISUTheme.Color.brandEmphasis)
            .frame(minHeight: YISUTheme.Size.minimumTouchTarget)
            .accessibilityIdentifier("wardrobe.filter.reset")

            Button("完成", action: apply)
                .buttonStyle(.borderedProminent)
                .tint(YISUTheme.Color.brandEmphasis)
                .frame(maxWidth: .infinity, minHeight: YISUTheme.Size.minimumTouchTarget)
                .accessibilityIdentifier("wardrobe.filter.apply")
        }
        .padding(.horizontal, YISUTheme.Spacing.md)
        .padding(.top, YISUTheme.Spacing.md)
        .padding(.bottom, YISUTheme.Spacing.sm)
        .background(YISUTheme.Color.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(YISUTheme.Color.border)
                .frame(height: 1)
        }
    }

    private func dimensionSection(_ dimension: WardrobeFilterDimension) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedDimensions.contains(dimension) },
                set: { isExpanded in
                    if isExpanded {
                        expandedDimensions.insert(dimension)
                    } else {
                        expandedDimensions.remove(dimension)
                    }
                }
            )
        ) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 88), spacing: YISUTheme.Spacing.sm)],
                alignment: .leading,
                spacing: YISUTheme.Spacing.sm
            ) {
                ForEach(WardrobeFilterPolicy.options(for: dimension, in: garments)) { option in
                    optionControl(option, for: dimension)
                }
            }
            .padding(.top, YISUTheme.Spacing.md)
        } label: {
            HStack(spacing: YISUTheme.Spacing.sm) {
                Text(dimension.title)
                    .font(YISUTheme.Typography.headline)
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                Spacer()
                Text(selectionSummary(for: dimension))
                    .font(YISUTheme.Typography.callout)
                    .foregroundStyle(YISUTheme.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(minHeight: YISUTheme.Size.minimumTouchTarget)
        }
        .tint(YISUTheme.Color.brandEmphasis)
        .padding(YISUTheme.Spacing.md)
        .background(YISUTheme.Color.surface, in: RoundedRectangle(cornerRadius: YISUTheme.Radius.medium))
        .accessibilityIdentifier("wardrobe.filter.dimension.\(dimension.rawValue)")
        .accessibilityValue(expandedDimensions.contains(dimension) ? "已展开" : "已收起")
    }

    private func optionControl(_ option: WardrobeFilterOption, for dimension: WardrobeFilterDimension) -> some View {
        let isSelected = selectedValues(for: dimension).contains(WardrobeFilterPolicy.normalized(option.value))

        return Button {
            draft.toggle(option.value, in: dimension)
        } label: {
            HStack(spacing: YISUTheme.Spacing.xs) {
                Text(option.value)
                    .lineLimit(1)
                Text("\(option.count)")
                    .foregroundStyle(isSelected ? YISUTheme.Color.textOnBrand.opacity(0.8) : YISUTheme.Color.textSecondary)
            }
            .font(YISUTheme.Typography.callout.weight(.medium))
            .foregroundStyle(isSelected ? YISUTheme.Color.textOnBrand : YISUTheme.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: YISUTheme.Size.minimumTouchTarget)
            .padding(.horizontal, YISUTheme.Spacing.sm)
            .background(isSelected ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.lavender, in: Capsule())
            .overlay {
                if !isSelected {
                    Capsule().stroke(YISUTheme.Color.border, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.value)，\(option.count) 件")
        .accessibilityValue(isSelected ? "已选中" : "未选中")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("wardrobe.filter.option.\(dimension.rawValue).\(WardrobeFilterPolicy.normalized(option.value))")
    }

    private func selectedValues(for dimension: WardrobeFilterDimension) -> Set<String> {
        switch dimension {
        case .category:
            return Set(draft.filter.categories.map(\.title).map(WardrobeFilterPolicy.normalized))
        case .season: return Set(draft.filter.seasons.map(WardrobeFilterPolicy.normalized))
        case .color: return Set(draft.filter.colors.map(WardrobeFilterPolicy.normalized))
        case .material: return Set(draft.filter.materials.map(WardrobeFilterPolicy.normalized))
        case .style: return Set(draft.filter.styles.map(WardrobeFilterPolicy.normalized))
        case .size: return Set(draft.filter.sizes.map(WardrobeFilterPolicy.normalized))
        case .storageLocation: return Set(draft.filter.storageLocations.map(WardrobeFilterPolicy.normalized))
        }
    }

    private func selectionSummary(for dimension: WardrobeFilterDimension) -> String {
        let values = selectedValues(for: dimension)
        guard !values.isEmpty else { return "不限" }
        return "已选 \(values.count) 项"
    }

    private func cancel() {
        didFinish = true
        onCancel()
    }

    private func apply() {
        didFinish = true
        onApply(draft.filter)
    }
}

private extension WardrobeFilterDimension {
    var title: String {
        switch self {
        case .category: "分类"
        case .season: "季节"
        case .color: "颜色"
        case .material: "材质"
        case .style: "风格"
        case .size: "尺码"
        case .storageLocation: "收纳位置"
        }
    }
}

#Preview("Filter sheet") {
    WardrobeFilterSheet(
        appliedFilter: WardrobeFilter(seasons: ["秋季"]),
        garments: [],
        onApply: { _ in },
        onCancel: {}
    )
}
