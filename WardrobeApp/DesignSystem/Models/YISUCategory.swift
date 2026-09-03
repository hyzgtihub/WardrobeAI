enum YISUCategory: String, Codable, CaseIterable, Equatable, Sendable {
    case all
    case tops
    case pants
    case outerwear
    case dresses
    case shoes
    case accessories
    case other

    var title: String {
        switch self {
        case .all: "全部"
        case .tops: "上衣"
        case .pants: "裤子"
        case .outerwear: "外套"
        case .dresses: "裙子"
        case .shoes: "鞋子"
        case .accessories: "配饰"
        case .other: "其他"
        }
    }

    var accessibilityIdentifier: String {
        "designSystem.category.\(rawValue)"
    }
}
