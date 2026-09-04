import SwiftUI
import UIKit

struct AddGarmentView: View {
    @Bindable var store: AddGarmentStore
    let account: UserAccount
    let onBack: () -> Void
    let onReselectPhoto: () -> Void
    let onCreated: (Garment) -> Void

    @State private var confirmsDiscard = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                photoSection
                requiredSection
                optionalSection
            }
            .scrollContentBackground(.hidden)
        }
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { submitButton }
        .navigationBarHidden(true)
        .alert("放弃当前更改？", isPresented: $confirmsDiscard) {
            Button("继续编辑", role: .cancel) {}
            Button("放弃更改", role: .destructive, action: onBack)
        } message: {
            Text("已选择的照片和填写内容不会被保存。")
        }
    }

    private var header: some View {
        HStack {
            Button { confirmsDiscard = true } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("返回")
            Spacer()
            Text("衣物信息")
                .font(YISUTheme.Typography.headline)
                .foregroundStyle(YISUTheme.Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, YISUTheme.Spacing.md)
        .padding(.top, YISUTheme.Spacing.xs)
    }

    private var photoSection: some View {
        Section("照片") {
            if let photo = store.draft.photo, let image = UIImage(data: photo.data) {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 132)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.medium))
                        .accessibilityLabel("当前衣物照片")

                    Button(action: onReselectPhoto) {
                        Label("换图", systemImage: "arrow.triangle.2.circlepath.camera")
                            .font(YISUTheme.Typography.callout.weight(.semibold))
                            .frame(minWidth: 76, minHeight: 44)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(YISUTheme.Spacing.sm)
                    .accessibilityIdentifier("addGarment.reselectPhoto")
                }
            }
        }
    }

    private var requiredSection: some View {
        Section("必填信息") {
            labeledField("名称", prompt: "例如：白色亚麻衬衫", text: $store.draft.name, id: "addGarment.name")

            VStack(alignment: .leading, spacing: YISUTheme.Spacing.sm) {
                Text("分类").font(YISUTheme.Typography.callout.weight(.semibold))
                flexibleButtons(YISUCategory.allCases.filter { $0 != .all }) { category in
                    selectionButton(
                        category.title,
                        selected: store.draft.category == category,
                        id: "addGarment.category.\(category.rawValue)"
                    ) { store.draft.category = category }
                }
            }

            VStack(alignment: .leading, spacing: YISUTheme.Spacing.sm) {
                Text("季节").font(YISUTheme.Typography.callout.weight(.semibold))
                flexibleButtons(Season.allCases) { season in
                    selectionButton(
                        season.title,
                        selected: store.draft.seasons.contains(season.rawValue),
                        id: "addGarment.season.\(season.rawValue)"
                    ) { toggleSeason(season.rawValue) }
                }
            }

            if let message = issueMessage {
                Text(message)
                    .font(YISUTheme.Typography.footnote)
                    .foregroundStyle(YISUTheme.Color.danger)
                    .accessibilityIdentifier("addGarment.error")
            }
        }
    }

    private var optionalSection: some View {
        Section("更多信息") {
            labeledField("收纳位置", prompt: "例如：主卧衣橱上层", text: $store.draft.storageLocation)
            labeledField("备注", prompt: "记录搭配或护理信息", text: $store.draft.notes)
            labeledField("颜色", prompt: "多个颜色用顿号分隔", text: Binding(
                get: { store.draft.colors.joined(separator: "、") },
                set: { store.draft.colors = split($0) }
            ))
            labeledField("品牌", prompt: "品牌", text: $store.draft.brand)
            labeledField("价格", prompt: "人民币", text: $store.draft.price, keyboard: .decimalPad)
            labeledField("尺码", prompt: "尺码", text: $store.draft.size)
            DatePicker("购买日期", selection: Binding(
                get: { store.draft.purchaseDate ?? Date() },
                set: { store.draft.purchaseDate = $0 }
            ), displayedComponents: .date)
            labeledField("材质", prompt: "材质", text: $store.draft.material)
            labeledField("风格", prompt: "风格", text: $store.draft.style)
        }
    }

    private var submitButton: some View {
        YISUButton(
            title: "完成添加",
            style: .primary,
            state: isSubmitting ? .loading : .normal,
            accessibilityIdentifier: "addGarment.submit"
        ) {
            Task {
                if let garment = await store.submit(account: account) {
                    onCreated(garment)
                }
            }
        }
        .padding(.horizontal, YISUTheme.Spacing.md)
        .padding(.vertical, YISUTheme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private func labeledField(
        _ label: String,
        prompt: String,
        text: Binding<String>,
        id: String? = nil,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
            Text(label).font(YISUTheme.Typography.callout.weight(.semibold))
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .frame(minHeight: 44)
                .accessibilityLabel(label)
                .accessibilityIdentifier(id ?? "")
        }
    }

    private func flexibleButtons<Item: RandomAccessCollection, Content: View>(
        _ items: Item,
        @ViewBuilder content: @escaping (Item.Element) -> Content
    ) -> some View where Item.Element: Hashable {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
            ForEach(Array(items), id: \.self, content: content)
        }
    }

    private func selectionButton(_ title: String, selected: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(YISUTheme.Typography.callout)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(selected ? YISUTheme.Color.textOnBrand : YISUTheme.Color.textPrimary)
                .background(selected ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.surfaceSubtle)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var isSubmitting: Bool {
        store.state == .validating || store.state == .uploadingPhoto || store.state == .creatingGarment
    }

    private var issueMessage: String? {
        if store.state == .uploadFailed { return "照片上传失败，请重试" }
        if store.state == .createFailed { return "衣物保存失败，请重试" }
        return switch store.issue {
        case .photoRequired: "请选择衣物照片"
        case .nameRequired: "请输入衣物名称"
        case .categoryRequired: "请选择衣物分类"
        case .seasonRequired: "请至少选择一个季节"
        case .invalidPrice: "价格应为不小于 0 且最多两位小数的金额"
        case nil: nil
        }
    }

    private func toggleSeason(_ season: String) {
        if let index = store.draft.seasons.firstIndex(of: season) {
            store.draft.seasons.remove(at: index)
        } else {
            store.draft.seasons.append(season)
        }
    }

    private func split(_ value: String) -> [String] {
        value.split(whereSeparator: { $0 == "、" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private enum Season: String, CaseIterable {
    case spring, summer, autumn, winter

    var title: String {
        switch self {
        case .spring: "春"
        case .summer: "夏"
        case .autumn: "秋"
        case .winter: "冬"
        }
    }
}
