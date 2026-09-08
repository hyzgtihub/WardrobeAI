import SwiftUI
import UIKit

struct AddGarmentView: View {
    @Bindable var store: AddGarmentStore
    let account: UserAccount
    let onBack: () -> Void
    let onReselectPhoto: () -> Void
    let onCreated: (Garment) -> Void

    @State private var confirmsDiscard = false
    @State private var picker: PickerKind?
    @State private var pendingCategory: YISUCategory?

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
        .confirmationDialog("更改分类将清除当前尺码", isPresented: Binding(
            get: { pendingCategory != nil }, set: { if !$0 { pendingCategory = nil } }
        )) {
            Button("继续并清除尺码", role: .destructive) {
                if let pendingCategory { store.draft.category = pendingCategory; store.draft.size = "" }
                pendingCategory = nil
            }
            Button("取消", role: .cancel) { pendingCategory = nil }
        }
        .sheet(item: $picker, content: pickerSheet)
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

            selectionRow("分类", value: store.draft.category?.title, id: "addGarment.category") { picker = .category }
            selectionRow("季节", value: GarmentFieldSelectionPolicy.summary(store.draft.seasons, kind: .season), id: "addGarment.seasons") { picker = .seasons }

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
            selectionRow("收纳位置", value: store.draft.storageLocation, id: "addGarment.storage") { picker = .storage }
            labeledField("备注", prompt: "记录搭配或护理信息", text: $store.draft.notes)
            selectionRow("颜色", value: GarmentFieldSelectionPolicy.summary(store.draft.colors), id: "addGarment.colors") { picker = .colors }
            labeledField("品牌", prompt: "品牌", text: $store.draft.brand)
            labeledField("价格", prompt: "人民币", text: $store.draft.price, keyboard: .decimalPad)
            if let category = store.draft.category, !GarmentFieldSelectionPolicy.sizes(for: category).isEmpty {
                selectionRow("尺码", value: store.draft.size, id: "addGarment.size") { picker = .size }
            }
            selectionRow("购买日期", value: dateText(store.draft.purchaseDate), id: "addGarment.purchaseDate") { picker = .purchaseDate }
            selectionRow("材质", value: GarmentFieldSelectionPolicy.summary(store.draft.materials), id: "addGarment.materials") { picker = .materials }
            selectionRow("风格", value: GarmentFieldSelectionPolicy.summary(store.draft.styles), id: "addGarment.styles") { picker = .styles }
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

    private func selectionRow(_ label: String, value: String?, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(YISUTheme.Typography.callout.weight(.semibold)).foregroundStyle(YISUTheme.Color.textPrimary)
                Spacer()
                Text(value.flatMap { $0.isEmpty ? nil : $0 } ?? "请选择").foregroundStyle(value?.isEmpty == false ? YISUTheme.Color.textSecondary : YISUTheme.Color.textPlaceholder).lineLimit(1)
                Image(systemName: "chevron.right").foregroundStyle(YISUTheme.Color.textPlaceholder)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    @ViewBuilder private func pickerSheet(_ kind: PickerKind) -> some View {
        switch kind {
        case .category:
            GarmentSingleSelectSheet(title: "选择分类", options: GarmentFieldOptions.categories.map(\.title), selected: store.draft.category?.title, accessibilityPrefix: "picker.category") { title in
                guard let category = GarmentFieldOptions.categories.first(where: { $0.title == title }) else { return }
                if let old = store.draft.category, GarmentFieldSelectionPolicy.sizeDecision(from: old, to: category, currentSize: store.draft.size) == .confirmClear {
                    pendingCategory = category
                } else {
                    if let old = store.draft.category, GarmentFieldSelectionPolicy.sizeDecision(from: old, to: category, currentSize: store.draft.size) == .clearWithoutConfirmation { store.draft.size = "" }
                    store.draft.category = category
                }
            }
        case .size:
            GarmentSingleSelectSheet(title: "选择尺码", options: store.draft.category.map(GarmentFieldSelectionPolicy.sizes) ?? [], selected: store.draft.size, accessibilityPrefix: "picker.size") { store.draft.size = $0 }
        case .seasons: multiSheet("选择季节", GarmentFieldOptions.seasons, store.draft.seasons, "picker.seasons") { store.draft.seasons = $0 }
        case .colors: multiSheet("选择颜色", GarmentFieldOptions.colors, store.draft.colors, "picker.colors") { store.draft.colors = $0 }
        case .materials: multiSheet("选择材质", GarmentFieldOptions.materials, store.draft.materials, "picker.materials") { store.draft.materials = $0 }
        case .styles: multiSheet("选择风格", GarmentFieldOptions.styles, store.draft.styles, "picker.styles") { store.draft.styles = $0 }
        case .storage: GarmentStorageLocationSheet(value: store.draft.storageLocation.isEmpty ? nil : store.draft.storageLocation) { store.draft.storageLocation = $0 ?? "" }
        case .purchaseDate: YISUPurchaseDateSheet(date: store.draft.purchaseDate) { store.draft.purchaseDate = $0 }
        }
    }

    private func multiSheet(_ title: String, _ options: [String], _ selection: [String], _ prefix: String, completion: @escaping ([String]) -> Void) -> some View {
        GarmentMultiSelectSheet(title: title, options: options, selection: selection, accessibilityPrefix: prefix, onComplete: completion)
    }

    private func dateText(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN"); formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
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

private enum PickerKind: String, Identifiable {
    case category, seasons, colors, size, materials, styles, storage, purchaseDate
    var id: String { rawValue }
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

struct GarmentSingleSelectSheet: View {
    let title: String
    let options: [String]
    let selected: String?
    let accessibilityPrefix: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(options, id: \.self) { option in
                Button {
                    onSelect(option)
                    dismiss()
                } label: {
                    HStack {
                        Text(option).foregroundStyle(YISUTheme.Color.textPrimary)
                        Spacer()
                        if option == selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(YISUTheme.Color.brandEmphasis)
                        }
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(option)
                .accessibilityValue(option == selected ? "已选中" : "未选中")
                .accessibilityIdentifier("\(accessibilityPrefix).\(option)")
            }
            .scrollContentBackground(.hidden)
            .background(YISUTheme.Color.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
    }
}

struct GarmentMultiSelectSheet: View {
    let title: String
    let options: [String]
    let initialSelection: [String]
    let accessibilityPrefix: String
    let onComplete: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection: [String]
    @State private var customValue = ""
    @State private var showsCustomInput = false

    init(title: String, options: [String], selection: [String], accessibilityPrefix: String, onComplete: @escaping ([String]) -> Void) {
        self.title = title
        self.options = options
        initialSelection = selection
        self.accessibilityPrefix = accessibilityPrefix
        self.onComplete = onComplete
        _selection = State(initialValue: selection)
        _showsCustomInput = State(initialValue: selection.contains { !options.contains($0) })
        _customValue = State(initialValue: selection.first { !options.contains($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section("已选 \(committedSelection.count) 项") {
                    ForEach(options, id: \.self) { option in
                        Button { toggle(option) } label: {
                            HStack {
                                Text(option).foregroundStyle(YISUTheme.Color.textPrimary)
                                Spacer()
                                Image(systemName: isSelected(option) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected(option) ? YISUTheme.Color.brandEmphasis : YISUTheme.Color.border)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .accessibilityValue(isSelected(option) ? "已选中" : "未选中")
                        .accessibilityIdentifier("\(accessibilityPrefix).\(option)")
                    }
                    if showsCustomInput {
                        TextField("输入其他内容", text: $customValue)
                            .textInputAutocapitalization(.never)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("\(accessibilityPrefix).custom")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(YISUTheme.Color.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onComplete(committedSelection)
                        dismiss()
                    }
                    .disabled(committedSelection == initialSelection)
                    .accessibilityIdentifier("\(accessibilityPrefix).complete")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
    }

    private var committedSelection: [String] {
        let presets = selection.filter { $0 != "其他" && options.contains($0) }
        return GarmentFieldSelectionPolicy.normalized(presets + (showsCustomInput ? [customValue] : []))
    }

    private func isSelected(_ option: String) -> Bool {
        option == "其他" ? showsCustomInput : selection.contains(option)
    }

    private func toggle(_ option: String) {
        if option == "其他" {
            showsCustomInput.toggle()
            if !showsCustomInput { customValue = "" }
        } else if let index = selection.firstIndex(of: option) {
            selection.remove(at: index)
        } else {
            selection.append(option)
        }
    }
}

struct GarmentStorageLocationSheet: View {
    let initialValue: String?
    let onComplete: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var primary: String?
    @State private var secondary: String?
    @State private var customPrimary = ""

    init(value: String?, onComplete: @escaping (String?) -> Void) {
        initialValue = value
        self.onComplete = onComplete
        let parts = value?.components(separatedBy: " · ") ?? []
        let first = parts.first
        _primary = State(initialValue: first.flatMap { GarmentFieldOptions.storagePrimary.contains($0) ? $0 : ($0.isEmpty ? nil : "其他") })
        _secondary = State(initialValue: parts.count > 1 ? parts[1] : nil)
        _customPrimary = State(initialValue: first.flatMap { GarmentFieldOptions.storagePrimary.contains($0) ? "" : $0 } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("收纳区域") {
                    optionGrid(GarmentFieldOptions.storagePrimary, selected: primary) { value in
                        primary = value
                        if value != "其他" { customPrimary = "" }
                    }
                    if primary == "其他" {
                        TextField("输入收纳区域", text: $customPrimary).frame(minHeight: 44)
                    }
                }
                if primary != nil {
                    Section("具体位置（可选）") {
                        optionGrid(GarmentFieldOptions.storageSecondary, selected: secondary) { secondary = $0 }
                    }
                }
                Section { Button("清除位置", role: .destructive) { primary = nil; secondary = nil; customPrimary = "" } }
            }
            .scrollContentBackground(.hidden)
            .background(YISUTheme.Color.background)
            .navigationTitle("收纳位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { onComplete(value); dismiss() }
                        .disabled(value == initialValue)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
    }

    private var value: String? {
        let first = primary == "其他" ? customPrimary.trimmingCharacters(in: .whitespacesAndNewlines) : primary
        guard let first, !first.isEmpty else { return nil }
        return secondary.map { "\(first) · \($0)" } ?? first
    }

    private func optionGrid(_ options: [String], selected: String?, select: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button { select(option) } label: {
                    Label(option, systemImage: selected == option ? "checkmark.circle.fill" : "circle")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityValue(selected == option ? "已选中" : "未选中")
            }
        }
    }
}

struct YISUPurchaseDateSheet: View {
    let initialDate: Date?
    let today: Date
    let onComplete: (Date?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Date?
    @State private var displayedMonth: Date
    private var calendar: Calendar { var value = Calendar(identifier: .iso8601); value.timeZone = TimeZone(secondsFromGMT: 0)!; value.firstWeekday = 2; return value }

    init(date: Date?, today: Date = Date(), onComplete: @escaping (Date?) -> Void) {
        initialDate = date
        self.today = today
        self.onComplete = onComplete
        _selection = State(initialValue: date)
        _displayedMonth = State(initialValue: PurchaseDateCalendar.initialMonth(existingDate: date, today: today))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Button { moveMonth(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("上个月")
                    Spacer()
                    Text(monthTitle).font(YISUTheme.Typography.title)
                    Spacer()
                    Button { moveMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .disabled(!model.canMoveToNextMonth).accessibilityLabel("下个月")
                }
                .padding(.horizontal, 8)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { Text($0).font(YISUTheme.Typography.footnote).foregroundStyle(YISUTheme.Color.textSecondary).frame(height: 28) }
                    ForEach(model.cells, id: \.date) { cell in
                        Button { select(cell.date) } label: {
                            Text("\(calendar.component(.day, from: cell.date))")
                                .font(YISUTheme.Typography.callout.weight(isSelected(cell.date) ? .semibold : .regular))
                                .foregroundStyle(dayColor(cell))
                                .frame(width: 40, height: 40)
                                .background(isSelected(cell.date) ? YISUTheme.Color.brandEmphasis : .clear, in: Circle())
                                .overlay { if cell.isToday && !isSelected(cell.date) { Circle().stroke(.green.opacity(0.55), lineWidth: 1.5) } }
                        }
                        .disabled(!cell.isSelectable)
                        .accessibilityLabel(dateLabel(cell.date))
                        .accessibilityValue(isSelected(cell.date) ? "已选中" : (cell.isToday ? "今天" : ""))
                        .accessibilityIdentifier("purchaseDate.day.\(dateID(cell.date))")
                    }
                }
                Button("清除日期", role: .destructive) { selection = nil }
                    .frame(minHeight: 44)
                    .disabled(selection == nil)
                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("购买日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("完成") { onComplete(selection); dismiss() }.disabled(sameDay(selection, initialDate)) }
            }
        }
        .presentationDetents([.height(560)])
        .presentationCornerRadius(28)
    }

    private var model: PurchaseDateCalendar { PurchaseDateCalendar(today: today, displayedMonth: displayedMonth, calendar: calendar) }
    private var monthTitle: String { let c = calendar.dateComponents([.year, .month], from: displayedMonth); return "\(c.year!) 年 \(c.month!) 月" }
    private func moveMonth(_ offset: Int) { displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth)! }
    private func select(_ date: Date) { selection = date; if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) { displayedMonth = PurchaseDateCalendar.initialMonth(existingDate: date, today: today) } }
    private func isSelected(_ date: Date) -> Bool { selection.map { calendar.isDate($0, inSameDayAs: date) } ?? false }
    private func sameDay(_ left: Date?, _ right: Date?) -> Bool { switch (left, right) { case (nil, nil): true; case let (l?, r?): calendar.isDate(l, inSameDayAs: r); default: false } }
    private func dayColor(_ cell: PurchaseDateCalendar.Cell) -> Color { if isSelected(cell.date) { return .white }; if !cell.isSelectable { return YISUTheme.Color.textPlaceholder.opacity(0.35) }; return cell.isInDisplayedMonth ? YISUTheme.Color.textPrimary : YISUTheme.Color.textSecondary }
    private func dateID(_ date: Date) -> String { let c = calendar.dateComponents([.year, .month, .day], from: date); return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!) }
    private func dateLabel(_ date: Date) -> String { dateID(date) }
}
