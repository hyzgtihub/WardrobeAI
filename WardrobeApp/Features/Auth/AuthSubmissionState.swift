enum AuthSubmissionState: Equatable, Sendable {
    case idle
    case submitting
    case emailExists
    case serviceFailure

    var allowsSubmission: Bool { self == .idle }

    var recovered: Self {
        switch self {
        case .emailExists, .serviceFailure: .idle
        case .idle, .submitting: self
        }
    }
}
