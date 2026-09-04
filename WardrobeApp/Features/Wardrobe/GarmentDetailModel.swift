import Foundation

enum GarmentFieldOptions {
    static let categories: [YISUCategory] = [.tops, .pants, .dresses, .outerwear, .shoes, .bags, .accessories, .other]
    static let seasons = ["春季", "夏季", "秋季", "冬季"]
    static let colors = ["黑色系", "白色系", "灰色系", "红色系", "橙色系", "黄色系", "绿色系", "蓝色系", "紫色系", "粉色系", "棕色系", "裸色系", "金色系", "银色系", "透明/无色", "彩色/多色", "其他"]
    static let materials = ["棉", "涤纶", "尼龙", "牛仔布", "麻", "丝", "羊毛", "羊绒", "莫代尔", "氨纶", "腨纶", "毛皮", "羽绒", "丝绒", "雪纺", "蕾丝", "欧根纱", "薄纱", "其他"]
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
