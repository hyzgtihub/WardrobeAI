import Foundation
import Observation

enum GarmentFieldOptions {
    static let categories: [YISUCategory] = [.tops, .pants, .dresses, .outerwear, .shoes, .bags, .accessories, .other]
    static let seasons = ["春季", "夏季", "秋季", "冬季"]
    static let colors = ["黑色系", "白色系", "灰色系", "红色系", "橙色系", "黄色系", "绿色系", "蓝色系", "紫色系", "粉色系", "棕色系", "裸色系", "金色系", "银色系", "透明/无色", "彩色/多色", "其他"]
    static let materials = ["棉", "涤纶", "尼龙", "牛仔布", "麻", "丝", "羊毛", "羊绒", "莫代尔", "氨纶", "腈纶", "毛皮", "羽绒", "丝绒", "雪纺", "蕾丝", "欧根纱", "薄纱", "其他"]
    static let styles = ["简约", "通勤", "休闲", "运动", "复古", "文艺", "中性", "甜美", "优雅", "街头", "学院", "度假", "性感", "民族", "其他"]
    static let apparelSizes = ["XS", "S", "M", "L", "XL", "XXL", "其他"]
    static let shoeSizes: [String] = stride(from: 35.0, through: 45.0, by: 0.5).map {
        $0.rounded() == $0 ? String(Int($0)) : String(format: "%.1f", $0)
    } + ["其他"]
    static let storagePrimary = ["主卧衣橱", "次卧衣橱", "玄关柜", "衣帽间", "储物柜", "其他"]
    static let storageSecondary = ["上层", "中层", "下层", "抽屉", "挂衣区", "叠放区"]
}

enum GarmentFieldSelectionPolicy {
    enum SummaryKind { case season, standard }
    enum SizeDecision: Equatable { case keep, confirmClear, clearWithoutConfirmation }

    static func normalized(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.compactMap { raw in
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, value.count <= 20 else { return nil }
            let key = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return seen.insert(key).inserted ? value : nil
        }
    }

    static func summary(_ values: [String], kind: SummaryKind = .standard) -> String {
        if kind == .season, Set(values) == Set(GarmentFieldOptions.seasons) { return "四季" }
        return values.joined(separator: "、")
    }

    static func sizes(for category: YISUCategory) -> [String] {
        switch category {
        case .tops, .pants, .dresses, .outerwear: GarmentFieldOptions.apparelSizes
        case .shoes: GarmentFieldOptions.shoeSizes
        case .all, .bags, .accessories, .other: []
        }
    }

    static func sizeDecision(from old: YISUCategory, to new: YISUCategory, currentSize: String) -> SizeDecision {
        let oldGroup = sizeGroup(old)
        let newGroup = sizeGroup(new)
        guard oldGroup != newGroup else { return .keep }
        return currentSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clearWithoutConfirmation : .confirmClear
    }

    private static func sizeGroup(_ category: YISUCategory) -> Int {
        switch category {
        case .tops, .pants, .dresses, .outerwear: 1
        case .shoes: 2
        case .all, .bags, .accessories, .other: 3
        }
    }
}

struct PurchaseDateCalendar: Sendable {
    struct Cell: Equatable, Sendable {
        let date: Date
        let isInDisplayedMonth: Bool
        let isSelectable: Bool
        let isToday: Bool
    }

    let today: Date
    let displayedMonth: Date
    let calendar: Calendar
    let cells: [Cell]
    let canMoveToNextMonth: Bool

    init(today: Date, displayedMonth: Date, calendar inputCalendar: Calendar = Calendar(identifier: .iso8601)) {
        var calendar = inputCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        self.calendar = calendar
        self.today = calendar.startOfDay(for: today)
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let normalizedMonth = calendar.date(from: components)!
        self.displayedMonth = normalizedMonth
        let weekday = calendar.component(.weekday, from: normalizedMonth)
        let mondayOffset = (weekday + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -mondayOffset, to: normalizedMonth)!
        cells = (0..<42).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: gridStart)!
            return Cell(
                date: date,
                isInDisplayedMonth: calendar.isDate(date, equalTo: normalizedMonth, toGranularity: .month),
                isSelectable: calendar.startOfDay(for: date) <= calendar.startOfDay(for: today),
                isToday: calendar.isDate(date, inSameDayAs: today)
            )
        }
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: normalizedMonth)!
        canMoveToNextMonth = nextMonth <= calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
    }

    static func initialMonth(existingDate: Date?, today: Date, calendar inputCalendar: Calendar = Calendar(identifier: .iso8601)) -> Date {
        var calendar = inputCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: calendar.dateComponents([.year, .month], from: existingDate ?? today))!
    }

    static var clearedSelection: Date? { nil }
}

struct GarmentDetailDraft: Equatable, Sendable {
    let id: UUID
    var name: String
    var subtitle: String
    var imageName: String
    var category: YISUCategory
    var seasons: [String]
    var storageLocation: String
    var notes: String
    var colors: [String]
    var brand: String
    var price: String
    var size: String
    var purchaseDate: String
    var materials: [String]
    var styles: [String]

    var imagePath: String { imageName }

    init(
        id: UUID,
        name: String,
        subtitle: String,
        imageName: String,
        category: YISUCategory,
        seasons: [String],
        storageLocation: String,
        notes: String,
        colors: [String],
        brand: String,
        price: String,
        size: String,
        purchaseDate: String,
        materials: [String],
        styles: [String]
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.imageName = imageName
        self.category = category
        self.seasons = seasons
        self.storageLocation = storageLocation
        self.notes = notes
        self.colors = colors
        self.brand = brand
        self.price = price
        self.size = size
        self.purchaseDate = purchaseDate
        self.materials = materials
        self.styles = styles
    }

    init(garment: Garment) {
        id = garment.id
        name = garment.name
        subtitle = garment.brand ?? garment.category.title
        imageName = garment.imagePath
        category = garment.category
        seasons = garment.seasons
        storageLocation = garment.storageLocation ?? ""
        notes = garment.notes ?? ""
        colors = garment.colors
        brand = garment.brand ?? ""
        price = Self.priceText(garment.price)
        size = garment.size ?? ""
        purchaseDate = garment.purchaseDate.map { Self.dateFormatter.string(from: $0) } ?? ""
        materials = garment.materials
        styles = garment.styles
    }

    static let whiteLinenShirt = GarmentDetailDraft(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111101")!,
        name: "白色亚麻衬衫",
        subtitle: "柔软亚麻 · 适合春夏通勤",
        imageName: "garment-white-linen-shirt",
        category: .tops,
        seasons: ["春季", "夏季"],
        storageLocation: "主卧衣橱 · 上层",
        notes: "适合搭配浅色长裤",
        colors: ["白色"],
        brand: "MUJI",
        price: "¥299",
        size: "M",
        purchaseDate: "2026.04.18",
        materials: ["亚麻", "棉"],
        styles: ["通勤", "简约"]
    )

    var summary: GarmentSummary {
        GarmentSummary(
            id: id,
            title: name,
            metadata: "\(seasons.map { String($0.prefix(1)) }.joined()) · \(category.title)",
            imagePath: imageName,
            category: category
        )
    }

    private static func priceText(_ price: Decimal?) -> String {
        guard let price else { return "" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "¥\(formatter.string(from: price as NSDecimalNumber) ?? "")"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

extension Garment {
    var summary: GarmentSummary {
        GarmentSummary(
            id: id,
            title: name,
            metadata: "\(seasons.joined(separator: "、")) · \(category.title)",
            imagePath: imagePath,
            category: category
        )
    }
}

enum GarmentDetailIssue: Equatable, Sendable {
    case nameRequired
    case seasonRequired
}

enum GarmentDetailPolicy {
    static let textDebounceNanoseconds: UInt64 = 800_000_000

    static func issue(for draft: GarmentDetailDraft) -> GarmentDetailIssue? {
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .nameRequired }
        if draft.seasons.isEmpty { return .seasonRequired }
        return nil
    }
}

enum GarmentAutosaveState: Equatable, Sendable {
    case idle, pending, saving, saved, failed, offline, photoFailed, loadingFailed

    var message: String {
        switch self {
        case .idle: ""
        case .pending: "等待保存"
        case .saving: "正在保存"
        case .saved: "已保存"
        case .failed: "保存失败，请重试"
        case .offline: "已离线，恢复网络后将自动保存"
        case .photoFailed: "图片更新失败"
        case .loadingFailed: "衣物信息加载失败"
        }
    }
}

@MainActor
@Observable
final class GarmentDetailStore {
    enum Field: Hashable, Sendable { case name, category, seasons, colors, brand, price, size, purchaseDate, materials, styles, storage, notes, image }

    var draft: GarmentDetailDraft
    private(set) var state: GarmentAutosaveState = .idle
    private(set) var validationMessage: String?
    private(set) var garment: Garment
    private(set) var canRetryPhoto = false
    var garmentUserID: UUID { garment.userID }

    private let repository: any GarmentRepository
    private let imageRepository: (any GarmentImageRepository)?
    private let imageProcessor: GarmentImageProcessor
    private let makeRevisionID: () -> UUID
    private let debounceNanoseconds: UInt64
    private var onPersisted: (Garment) -> Void
    @ObservationIgnored private var debounceTasks: [Field: Task<Void, Never>] = [:]
    @ObservationIgnored private var saveTasks: [Field: Task<Void, Never>] = [:]
    @ObservationIgnored private var pendingFields: Set<Field> = []
    @ObservationIgnored private var failedFields: Set<Field> = []
    @ObservationIgnored private var pendingPhotoData: Data?
    @ObservationIgnored private var isReplacingPhoto = false

    init(
        garment: Garment,
        repository: any GarmentRepository,
        imageRepository: (any GarmentImageRepository)? = nil,
        imageProcessor: GarmentImageProcessor = GarmentImageProcessor(),
        makeRevisionID: @escaping () -> UUID = UUID.init,
        debounceNanoseconds: UInt64 = GarmentDetailPolicy.textDebounceNanoseconds,
        onPersisted: @escaping (Garment) -> Void = { _ in }
    ) {
        self.garment = garment
        draft = GarmentDetailDraft(garment: garment)
        self.repository = repository
        self.imageRepository = imageRepository
        self.imageProcessor = imageProcessor
        self.makeRevisionID = makeRevisionID
        self.debounceNanoseconds = debounceNanoseconds
        self.onPersisted = onPersisted
    }

    func setOnPersisted(_ action: @escaping (Garment) -> Void) { onPersisted = action }

    func editName(_ value: String) { draft.name = value; schedule(.name) }
    func editBrand(_ value: String) { draft.brand = value; schedule(.brand) }
    func editPrice(_ value: String) { draft.price = value; schedule(.price) }
    func editNotes(_ value: String) { draft.notes = value; schedule(.notes) }
    func setCategory(_ value: YISUCategory, clearSize: Bool = false) { draft.category = value; if clearSize { draft.size = "" }; enqueue(.category) }
    func setSeasons(_ value: [String]) { draft.seasons = value; enqueue(.seasons) }
    func setColors(_ value: [String]) { draft.colors = value; enqueue(.colors) }
    func setSize(_ value: String?) { draft.size = value ?? ""; enqueue(.category) }
    func setPurchaseDate(_ value: Date?) { draft.purchaseDate = Self.dateText(value); enqueue(.purchaseDate) }
    func setMaterials(_ value: [String]) { draft.materials = value; enqueue(.materials) }
    func setStyles(_ value: [String]) { draft.styles = value; enqueue(.styles) }
    func setStorage(_ value: String?) { draft.storageLocation = value ?? ""; enqueue(.storage) }

    func flush(_ field: Field) async {
        debounceTasks[field]?.cancel()
        debounceTasks[field] = nil
        enqueue(field)
        await waitForSaves()
    }

    func retryFailedField(_ field: Field) { enqueue(field) }
    func retryFailedFields() { for field in failedFields { enqueue(field) } }
    func retryPhotoReplacement() async { if let pendingPhotoData { await replacePhoto(data: pendingPhotoData) } }

    func cancelPendingWork() {
        debounceTasks.values.forEach { $0.cancel() }
        saveTasks.values.forEach { $0.cancel() }
        debounceTasks.removeAll()
        saveTasks.removeAll()
        pendingFields.removeAll()
        failedFields.removeAll()
    }

    func replacePhoto(data: Data) async {
        guard !isReplacingPhoto, let imageRepository else { return }
        isReplacingPhoto = true
        defer { isReplacingPhoto = false }
        pendingPhotoData = data
        canRetryPhoto = false
        let processed: GarmentImage
        do { processed = try imageProcessor.process(data) } catch { state = .photoFailed; pendingPhotoData = nil; return }
        let oldPath = garment.imagePath
        let newPath = GarmentImage.revisionPath(userID: garment.userID, garmentID: garment.id, revisionID: makeRevisionID())
        state = .saving
        do { try await imageRepository.uploadJPEG(processed.data, path: newPath) } catch { state = .photoFailed; canRetryPhoto = true; return }
        do {
            let saved = try await repository.updateGarment(id: garment.id, changes: GarmentChanges(imagePath: newPath))
            garment.imagePath = saved.imagePath
            draft.imageName = saved.imagePath
            onPersisted(garment)
            state = .saved
            pendingPhotoData = nil
            canRetryPhoto = false
            try? await imageRepository.deleteImage(path: oldPath)
        } catch {
            try? await imageRepository.deleteImage(path: newPath)
            state = .photoFailed
            canRetryPhoto = true
        }
    }

    func delete() async -> Bool {
        guard state != .saving else { return false }
        state = .saving
        do {
            try await imageRepository?.deleteImage(path: garment.imagePath)
            try await repository.deleteGarment(id: garment.id)
            state = .saved
            return true
        } catch {
            state = .failed
            return false
        }
    }

    func waitForSaves() async {
        while !saveTasks.isEmpty || !debounceTasks.isEmpty || !pendingFields.isEmpty {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    private func schedule(_ field: Field) {
        debounceTasks[field]?.cancel()
        state = .pending
        validationMessage = nil
        debounceTasks[field] = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard !Task.isCancelled else { return }
            debounceTasks[field] = nil
            enqueue(field)
        }
    }

    private func enqueue(_ field: Field) {
        pendingFields.insert(field)
        state = .pending
        guard saveTasks[field] == nil else { return }
        saveTasks[field] = Task { [weak self] in await self?.runSaveLoop(field) }
    }

    private func runSaveLoop(_ field: Field) async {
        while pendingFields.remove(field) != nil {
            guard let changes = changes(for: field) else {
                state = .failed
                continue
            }
            if changes.isEmpty {
                state = pendingFields.isEmpty ? .saved : .pending
                validationMessage = nil
                continue
            }
            state = .saving
            do {
                let saved = try await repository.updateGarment(id: garment.id, changes: changes)
                mergePersistedField(field, from: saved)
                onPersisted(garment)
                failedFields.remove(field)
                state = pendingFields.isEmpty ? .saved : .pending
                validationMessage = nil
            } catch {
                failedFields.insert(field)
                state = .failed
            }
        }
        saveTasks[field] = nil
    }

    private func changes(for field: Field) -> GarmentChanges? {
        switch field {
        case .name:
            let value = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { validationMessage = "名称不能为空"; return nil }
            return value == garment.name ? GarmentChanges() : GarmentChanges(name: value)
        case .category:
            guard draft.category != garment.category || draft.size != (garment.size ?? "") else { return GarmentChanges() }
            return GarmentChanges(
                category: draft.category == garment.category ? nil : draft.category,
                size: draft.size == (garment.size ?? "") ? nil : nullable(draft.size)
            )
        case .seasons:
            guard !draft.seasons.isEmpty else { validationMessage = "请至少选择一个季节"; return nil }
            return draft.seasons == garment.seasons ? GarmentChanges() : GarmentChanges(seasons: draft.seasons)
        case .colors: return draft.colors == garment.colors ? GarmentChanges() : GarmentChanges(colors: draft.colors)
        case .brand: return draft.brand == (garment.brand ?? "") ? GarmentChanges() : GarmentChanges(brand: nullable(draft.brand))
        case .price:
            let value = draft.price.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespaces)
            if value.isEmpty { return garment.price == nil ? GarmentChanges() : GarmentChanges(price: .clear) }
            guard value.range(of: #"^\d+(?:\.\d{1,2})?$"#, options: .regularExpression) != nil, let price = Decimal(string: value), price >= 0 else { validationMessage = "价格格式不正确"; return nil }
            return price == garment.price ? GarmentChanges() : GarmentChanges(price: .value(price))
        case .size: return draft.size == (garment.size ?? "") ? GarmentChanges() : GarmentChanges(size: nullable(draft.size))
        case .purchaseDate:
            let date = Self.date(draft.purchaseDate)
            if draft.purchaseDate.isEmpty { return garment.purchaseDate == nil ? GarmentChanges() : GarmentChanges(purchaseDate: .clear) }
            return date == garment.purchaseDate ? GarmentChanges() : GarmentChanges(purchaseDate: date.map(NullableChange.value))
        case .materials: return draft.materials == garment.materials ? GarmentChanges() : GarmentChanges(materials: draft.materials)
        case .styles: return draft.styles == garment.styles ? GarmentChanges() : GarmentChanges(styles: draft.styles)
        case .storage: return draft.storageLocation == (garment.storageLocation ?? "") ? GarmentChanges() : GarmentChanges(storageLocation: nullable(draft.storageLocation))
        case .notes: return draft.notes == (garment.notes ?? "") ? GarmentChanges() : GarmentChanges(notes: nullable(draft.notes))
        case .image: return GarmentChanges(imagePath: draft.imageName)
        }
    }

    private func nullable(_ value: String) -> NullableChange<String> {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? .clear : .value(trimmed)
    }

    private func mergePersistedField(_ field: Field, from saved: Garment) {
        switch field {
        case .name: garment.name = saved.name
        case .category: garment.category = saved.category; garment.size = saved.size
        case .seasons: garment.seasons = saved.seasons
        case .colors: garment.colors = saved.colors
        case .brand: garment.brand = saved.brand
        case .price: garment.price = saved.price
        case .size: garment.size = saved.size
        case .purchaseDate: garment.purchaseDate = saved.purchaseDate
        case .materials: garment.materials = saved.materials
        case .styles: garment.styles = saved.styles
        case .storage: garment.storageLocation = saved.storageLocation
        case .notes: garment.notes = saved.notes
        case .image: garment.imagePath = saved.imagePath
        }
        garment.updatedAt = max(garment.updatedAt, saved.updatedAt)
    }

    private static func dateText(_ date: Date?) -> String {
        guard let date else { return "" }; return displayDateFormatter.string(from: date)
    }
    private static func date(_ text: String) -> Date? { displayDateFormatter.date(from: text) }
    private static let displayDateFormatter: DateFormatter = { let f = DateFormatter(); f.calendar = Calendar(identifier: .iso8601); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(secondsFromGMT: 0); f.dateFormat = "yyyy.MM.dd"; return f }()
}
