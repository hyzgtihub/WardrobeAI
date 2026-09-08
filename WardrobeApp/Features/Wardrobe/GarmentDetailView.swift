import SwiftUI
import PhotosUI

struct GarmentDetailView: View {
    @Bindable var store: GarmentDetailStore
    let onBack: () -> Void
    let imageRepository: (any GarmentImageRepository)?
    let onChangePhoto: () -> Void
    let onDelete: () -> Void

    @State private var picker: DetailPicker?
    @State private var textEditor: TextEditorKind?
    @State private var editorText = ""
    @State private var confirmsDelete = false
    @State private var pendingCategory: YISUCategory?
    @FocusState private var nameFocused: Bool
    @State private var photoItem: PhotosPickerItem?
    @State private var pendingPhotoData: Data?
    @State private var confirmsPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: YISUTheme.Spacing.lg) {
                header
                YISUPhotoHero(
                    imageName: store.draft.imageName,
                    imageRepository: imageRepository,
                    status: store.state,
                    onChangePhoto: onChangePhoto,
                    photoSelection: $photoItem
                )
                identity
                infoCard(primaryRows)
                infoCard(secondaryRows)
                if let message = store.validationMessage { Text(message).font(YISUTheme.Typography.footnote).foregroundStyle(YISUTheme.Color.danger) }
                if store.state == .failed { YISUButton(title: "重试保存", style: .secondary, state: .normal, accessibilityIdentifier: "garmentDetail.retrySave") { store.retryFailedFields() } }
                if store.state == .photoFailed, store.canRetryPhoto { YISUButton(title: "重试换图", style: .secondary, state: .normal, accessibilityIdentifier: "garmentDetail.retryPhoto") { Task { await store.retryPhotoReplacement() } } }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(item: $picker, content: pickerSheet)
        .alert(textEditor?.title ?? "修改信息", isPresented: Binding(get: { textEditor != nil }, set: { if !$0 { textEditor = nil } })) {
            TextField(textEditor?.title ?? "", text: $editorText)
            Button("取消", role: .cancel) { textEditor = nil }
            Button("确认") { applyTextEditor() }
        } message: { Text("停止输入后将自动保存") }
        .confirmationDialog("删除这件衣物？", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive, action: onDelete)
            Button("取消", role: .cancel) {}
        } message: { Text("删除后无法恢复。") }
        .confirmationDialog("更改分类将清除当前尺码", isPresented: Binding(get: { pendingCategory != nil }, set: { if !$0 { pendingCategory = nil } })) {
            Button("继续并清除尺码", role: .destructive) { if let pendingCategory { store.setCategory(pendingCategory, clearSize: true) }; pendingCategory = nil }
            Button("取消", role: .cancel) { pendingCategory = nil }
        }
        .confirmationDialog("使用这张照片替换当前图片？", isPresented: $confirmsPhoto) {
            Button("确认换图") { if let pendingPhotoData { Task { await store.replacePhoto(data: pendingPhotoData) } }; pendingPhotoData = nil }
            Button("取消", role: .cancel) { pendingPhotoData = nil }
        } message: { Text("确认后将立即上传并自动保存。") }
        .onChange(of: nameFocused) { _, focused in if !focused { Task { await store.flush(.name) } } }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { pendingPhotoData = data; confirmsPhoto = true }
                photoItem = nil
            }
        }
    }

    private var header: some View {
        HStack {
            iconButton("chevron.left", id: "garmentDetail.back", action: onBack)
            Spacer()
            VStack(spacing: 2) {
                Text("衣物详情").font(YISUTheme.Typography.headline)
                if !store.state.message.isEmpty { Text(store.state.message).font(YISUTheme.Typography.footnote).foregroundStyle(store.state == .failed ? YISUTheme.Color.danger : YISUTheme.Color.textSecondary) }
            }
            Spacer()
            Menu {
                Button("删除这件衣物", role: .destructive) { confirmsDelete = true }
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle()) }
                .accessibilityLabel("更多操作").accessibilityIdentifier("garmentDetail.more")
        }
        .foregroundStyle(YISUTheme.Color.textPrimary).padding(.top, 6)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("衣物名称", text: Binding(get: { store.draft.name }, set: { store.editName($0) }))
                    .font(.system(size: 28, weight: .bold, design: .rounded)).focused($nameFocused)
                    .accessibilityLabel("衣物名称").accessibilityIdentifier("garmentDetail.name")
                Button { nameFocused = true } label: { Image(systemName: "pencil").frame(width: 44, height: 44) }.accessibilityLabel("修改名称")
            }
            Text(store.draft.subtitle).font(YISUTheme.Typography.callout).foregroundStyle(YISUTheme.Color.textSecondary)
            HStack(spacing: 8) { chip(store.draft.category.title); ForEach(store.draft.seasons, id: \.self) { chip($0) } }
            Text("轻触名称或任一字段即可修改 · 系统自动保存").font(YISUTheme.Typography.footnote).foregroundStyle(YISUTheme.Color.textPlaceholder)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryRows: [DetailRow] {[
        .init("分类", store.draft.category.title, "category") { picker = .category },
        .init("季节", GarmentFieldSelectionPolicy.summary(store.draft.seasons, kind: .season), "seasons") { picker = .seasons },
        .init("收纳位置", store.draft.storageLocation, "storage") { picker = .storage },
        .init("备注", store.draft.notes, "notes") { openText(.notes, store.draft.notes) }
    ]}

    private var secondaryRows: [DetailRow] {
        var rows = [
            DetailRow("颜色", GarmentFieldSelectionPolicy.summary(store.draft.colors), "colors") { picker = .colors },
            DetailRow("品牌", store.draft.brand, "brand") { openText(.brand, store.draft.brand) },
            DetailRow("价格", store.draft.price, "price") { openText(.price, store.draft.price) }
        ]
        if !GarmentFieldSelectionPolicy.sizes(for: store.draft.category).isEmpty { rows.append(.init("尺码", store.draft.size, "size") { picker = .size }) }
        rows += [
            .init("购买日期", store.draft.purchaseDate, "purchaseDate") { picker = .purchaseDate },
            .init("材质", GarmentFieldSelectionPolicy.summary(store.draft.materials), "materials") { picker = .materials },
            .init("风格", GarmentFieldSelectionPolicy.summary(store.draft.styles), "styles") { picker = .styles }
        ]
        return rows
    }

    private func infoCard(_ rows: [DetailRow]) -> some View { VStack(spacing: 0) { ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in YISUEditableFieldRow(title: row.title, value: row.value, identifier: "garmentDetail.field.\(row.id)", action: row.action); if index < rows.count - 1 { Divider() } } }.padding(.horizontal, 16).background(YISUTheme.Color.surface, in: RoundedRectangle(cornerRadius: 24)) }

    @ViewBuilder private func pickerSheet(_ picker: DetailPicker) -> some View {
        switch picker {
        case .category: GarmentSingleSelectSheet(title: "选择分类", options: GarmentFieldOptions.categories.map(\.title), selected: store.draft.category.title, accessibilityPrefix: "picker.category") { title in guard let value = GarmentFieldOptions.categories.first(where: { $0.title == title }) else { return }; if GarmentFieldSelectionPolicy.sizeDecision(from: store.draft.category, to: value, currentSize: store.draft.size) == .confirmClear { pendingCategory = value } else { store.setCategory(value, clearSize: GarmentFieldSelectionPolicy.sizeDecision(from: store.draft.category, to: value, currentSize: store.draft.size) == .clearWithoutConfirmation) } }
        case .size: GarmentSingleSelectSheet(title: "选择尺码", options: GarmentFieldSelectionPolicy.sizes(for: store.draft.category), selected: store.draft.size, accessibilityPrefix: "picker.size") { store.setSize($0) }
        case .seasons: multi("选择季节", GarmentFieldOptions.seasons, store.draft.seasons, "picker.seasons") { store.setSeasons($0) }
        case .colors: multi("选择颜色", GarmentFieldOptions.colors, store.draft.colors, "picker.colors") { store.setColors($0) }
        case .materials: multi("选择材质", GarmentFieldOptions.materials, store.draft.materials, "picker.materials") { store.setMaterials($0) }
        case .styles: multi("选择风格", GarmentFieldOptions.styles, store.draft.styles, "picker.styles") { store.setStyles($0) }
        case .storage: GarmentStorageLocationSheet(value: store.draft.storageLocation.isEmpty ? nil : store.draft.storageLocation) { store.setStorage($0) }
        case .purchaseDate: YISUPurchaseDateSheet(date: detailDate) { store.setPurchaseDate($0) }
        }
    }
    private func multi(_ title: String, _ options: [String], _ selected: [String], _ prefix: String, _ done: @escaping ([String]) -> Void) -> some View { GarmentMultiSelectSheet(title: title, options: options, selection: selected, accessibilityPrefix: prefix, onComplete: done) }
    private var detailDate: Date? { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy.MM.dd"; return f.date(from: store.draft.purchaseDate) }
    private func openText(_ kind: TextEditorKind, _ value: String) { editorText = value; textEditor = kind }
    private func applyTextEditor() { guard let kind = textEditor else { return }; switch kind { case .brand: store.editBrand(editorText); case .price: store.editPrice(editorText); case .notes: store.editNotes(editorText) }; textEditor = nil }
    private func chip(_ title: String) -> some View { Text(title).font(YISUTheme.Typography.footnote.weight(.semibold)).foregroundStyle(YISUTheme.Color.brandEmphasis).padding(.horizontal, 12).frame(height: 32).background(YISUTheme.Color.lavender, in: Capsule()) }
    private func iconButton(_ symbol: String, id: String, action: @escaping () -> Void) -> some View { Button(action: action) { Image(systemName: symbol).frame(width: 44, height: 44).contentShape(Rectangle()) }.accessibilityIdentifier(id) }
}

private struct DetailRow: Identifiable { let title: String; let value: String; let id: String; let action: () -> Void; init(_ title: String, _ value: String, _ id: String, action: @escaping () -> Void) { self.title = title; self.value = value; self.id = id; self.action = action } }
private enum DetailPicker: String, Identifiable { case category, seasons, colors, size, purchaseDate, materials, styles, storage; var id: String { rawValue } }
private enum TextEditorKind { case brand, price, notes; var title: String { switch self { case .brand: "修改品牌"; case .price: "修改价格"; case .notes: "修改备注" } } }

#Preview("P09 · 衣物详情") {
    GarmentDetailView(
        store: GarmentDetailStore(garment: .previewGarment, repository: PreviewGarmentRepository()),
        onBack: {}, imageRepository: nil, onChangePhoto: {}, onDelete: {}
    )
}

private extension Garment { static let previewGarment = Garment(id: UUID(), userID: UUID(), wardrobeID: UUID(), imagePath: "garment-white-linen-shirt", name: "白色亚麻衬衫", category: .tops, seasons: ["春季", "夏季"], colors: ["白色系"], brand: "MUJI", price: 299, size: "M", purchaseDate: nil, materials: ["麻"], styles: ["通勤"], storageLocation: "主卧衣橱 · 上层", notes: "", createdAt: Date(), updatedAt: Date(), deletedAt: nil) }
private struct PreviewGarmentRepository: GarmentRepository { func fetchGarments(wardrobeID: UUID) async throws -> [Garment] { [] }; func createGarment(_ input: NewGarment) async throws -> Garment { .previewGarment }; func updateGarment(id: UUID, changes: GarmentChanges) async throws -> Garment { .previewGarment } }
