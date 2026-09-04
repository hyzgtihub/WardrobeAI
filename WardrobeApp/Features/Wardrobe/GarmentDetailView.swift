import SwiftUI

struct GarmentDetailView: View {
    @State private var draft: GarmentDetailDraft
    @State private var autosaveState: GarmentAutosaveState = .saved
    @State private var activeEditor: DetailEditor?
    @State private var editorText = ""
    @FocusState private var nameFocused: Bool

    let onBack: () -> Void
    let imageRepository: (any GarmentImageRepository)?
    let onChange: (GarmentDetailDraft) -> Void
    let onDelete: () -> Void

    init(
        garment: GarmentDetailDraft,
        onBack: @escaping () -> Void = {},
        imageRepository: (any GarmentImageRepository)? = nil,
        onChange: @escaping (GarmentDetailDraft) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) {
        _draft = State(initialValue: garment)
        self.onBack = onBack
        self.imageRepository = imageRepository
        self.onChange = onChange
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(spacing: YISUTheme.Spacing.lg) {
                header
                YISUPhotoHero(imageName: draft.imageName, imageRepository: imageRepository, status: autosaveState) {
                    autosaveState = .photoFailed
                }
                identity
                infoCard(primaryRows)
                infoCard(secondaryRows)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert(activeEditor?.title ?? "修改信息", isPresented: Binding(
            get: { activeEditor != nil },
            set: { if !$0 { activeEditor = nil } }
        )) {
            TextField(activeEditor?.title ?? "", text: $editorText)
            Button("取消", role: .cancel) { activeEditor = nil }
            Button("确认") { applyEditor() }
        } message: {
            Text("确认后将自动保存")
        }
        .task(id: draft.name) {
            guard nameFocused else { return }
            autosaveState = .pending
            try? await Task.sleep(nanoseconds: GarmentDetailPolicy.textDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            save()
        }
    }

    private var header: some View {
        HStack {
            iconButton("chevron.left", id: "garmentDetail.back", action: onBack)
            Spacer()
            Text("衣物详情")
                .font(YISUTheme.Typography.headline)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .accessibilityIdentifier("garmentDetail.title")
            Spacer()
            Menu {
                Button("删除这件衣物", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(YISUTheme.Color.textPrimary)
            .accessibilityLabel("更多操作")
            .accessibilityIdentifier("garmentDetail.more")
        }
        .padding(.top, 6)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("衣物名称", text: $draft.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                    .focused($nameFocused)
                    .accessibilityLabel("衣物名称")
                    .accessibilityIdentifier("garmentDetail.name")
                Button { nameFocused = true } label: {
                    Image(systemName: "pencil")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("修改名称")
            }
            Text(draft.subtitle)
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textSecondary)
            HStack(spacing: 8) {
                chip(draft.category.title)
                ForEach(draft.seasons, id: \.self) { chip($0) }
            }
            Text("轻触名称或任一字段即可修改 · 系统自动保存")
                .font(YISUTheme.Typography.footnote)
                .foregroundStyle(YISUTheme.Color.textPlaceholder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryRows: [DetailRow] {
        [
            .init("分类", draft.category.title, "category") { draft.category = draft.category == .tops ? .outerwear : .tops; save() },
            .init("季节", draft.seasons.joined(separator: "、"), "seasons") { draft.seasons = draft.seasons == ["春季", "夏季"] ? ["秋季"] : ["春季", "夏季"]; save() },
            .init("收纳位置", draft.storageLocation, "storage") { open(.storage, value: draft.storageLocation) },
            .init("备注", draft.notes, "notes") { open(.notes, value: draft.notes) }
        ]
    }

    private var secondaryRows: [DetailRow] {
        [
            .init("颜色", draft.colors.joined(separator: "、"), "colors") { open(.colors, value: draft.colors.joined(separator: "、")) },
            .init("品牌", draft.brand, "brand") { open(.brand, value: draft.brand) },
            .init("价格", draft.price, "price") { open(.price, value: draft.price) },
            .init("尺码", draft.size, "size") { open(.size, value: draft.size) },
            .init("购买日期", draft.purchaseDate, "purchaseDate") { open(.purchaseDate, value: draft.purchaseDate) },
            .init("材质", draft.materials.joined(separator: "、"), "materials") { open(.materials, value: draft.materials.joined(separator: "、")) },
            .init("风格", draft.styles.joined(separator: "、"), "styles") { open(.styles, value: draft.styles.joined(separator: "、")) }
        ]
    }

    private func infoCard(_ rows: [DetailRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                YISUEditableFieldRow(title: row.title, value: row.value, identifier: "garmentDetail.field.\(row.id)", action: row.action)
                if index < rows.count - 1 { Divider().foregroundStyle(YISUTheme.Color.border) }
            }
        }
        .padding(.horizontal, 16)
        .background(YISUTheme.Color.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func save() {
        guard GarmentDetailPolicy.issue(for: draft) == nil else { autosaveState = .failed; return }
        autosaveState = .saving
        onChange(draft)
        withAnimation(.easeOut(duration: 0.2)) { autosaveState = .saved }
    }

    private func open(_ editor: DetailEditor, value: String) {
        editorText = value
        activeEditor = editor
    }

    private func applyEditor() {
        guard let editor = activeEditor else { return }
        switch editor {
        case .storage: draft.storageLocation = editorText
        case .notes: draft.notes = editorText
        case .colors: draft.colors = split(editorText)
        case .brand: draft.brand = editorText
        case .price: draft.price = editorText
        case .size: draft.size = editorText
        case .purchaseDate: draft.purchaseDate = editorText
        case .materials: draft.materials = split(editorText)
        case .styles: draft.styles = split(editorText)
        }
        activeEditor = nil
        save()
    }

    private func split(_ value: String) -> [String] {
        value.split(whereSeparator: { $0 == "、" || $0 == "," }).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func chip(_ title: String) -> some View {
        Text(title)
            .font(YISUTheme.Typography.footnote.weight(.semibold))
            .foregroundStyle(YISUTheme.Color.brandEmphasis)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(YISUTheme.Color.lavender, in: Capsule())
    }

    private func iconButton(_ symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .foregroundStyle(YISUTheme.Color.textPrimary)
        .accessibilityIdentifier(id)
    }
}

private struct DetailRow: Identifiable {
    let title: String
    let value: String
    let id: String
    let action: () -> Void
    init(_ title: String, _ value: String, _ id: String, action: @escaping () -> Void) {
        self.title = title; self.value = value; self.id = id; self.action = action
    }
}

private enum DetailEditor {
    case storage, notes, colors, brand, price, size, purchaseDate, materials, styles

    var title: String {
        switch self {
        case .storage: "修改收纳位置"
        case .notes: "修改备注"
        case .colors: "修改颜色"
        case .brand: "修改品牌"
        case .price: "修改价格"
        case .size: "修改尺码"
        case .purchaseDate: "修改购买日期"
        case .materials: "修改材质"
        case .styles: "修改风格"
        }
    }
}

#Preview("P09 · 衣物详情") { GarmentDetailView(garment: .whiteLinenShirt) }
