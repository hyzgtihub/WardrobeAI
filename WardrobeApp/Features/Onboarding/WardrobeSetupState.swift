enum WardrobeSetupState: String, Equatable, Sendable {
    case creating
    case creationFailed
    case created
    case currentRole
    case loadingCurrentRole
    case currentRoleFailed

    var allowsRetry: Bool {
        self == .creationFailed || self == .currentRoleFailed
    }

    var allowsContinue: Bool {
        self == .created || self == .currentRole
    }
}
