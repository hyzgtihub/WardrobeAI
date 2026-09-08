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

enum SignUpVerificationState: Equatable, Sendable {
    case idle
    case sending
    case codeSent(secondsRemaining: Int)
    case verifying

    var locksCredentials: Bool {
        switch self {
        case .sending, .codeSent, .verifying: true
        case .idle: false
        }
    }

    var allowsVerification: Bool {
        if case .codeSent = self { return true }
        return false
    }

    var allowsCodeRequest: Bool {
        switch self {
        case .idle: true
        case .codeSent(0): true
        case .sending, .verifying, .codeSent: false
        }
    }

    var secondsRemaining: Int {
        if case let .codeSent(seconds) = self { return seconds }
        return 0
    }

    mutating func tick() {
        guard case let .codeSent(seconds) = self, seconds > 0 else { return }
        self = .codeSent(secondsRemaining: seconds - 1)
    }

    mutating func reset() { self = .idle }
}
