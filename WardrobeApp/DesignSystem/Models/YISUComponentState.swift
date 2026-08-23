enum YISUControlState: Equatable, Sendable {
    case normal
    case pressed
    case disabled
    case loading

    var isInteractive: Bool {
        self != .disabled && self != .loading
    }
}

enum YISUGarmentCardState: Equatable, Sendable {
    case normal
    case pressed
    case loading
    case imageError
}
