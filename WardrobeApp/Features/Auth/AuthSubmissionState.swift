enum AuthSubmissionState: Equatable, Sendable {
    case idle
    case submitting
    case emailExists
    case serviceFailure

    var allowsSubmission: Bool { self == .idle }

    var blocksRegistrationDetails: Bool { self == .emailExists }

    var recovered: Self {
        switch self {
        case .emailExists, .serviceFailure: .idle
        case .idle, .submitting: self
        }
    }
}

struct SignUpOperationGeneration: Equatable, Sendable {
    private(set) var current = 0

    mutating func invalidate() {
        current &+= 1
    }

    func accepts(_ operation: Int) -> Bool {
        operation == current
    }
}

enum SignUpVerificationState: Equatable, Sendable {
    case idle
    case sending
    case codeSent(secondsRemaining: Int)
    case verifying

    var locksPasswords: Bool {
        switch self {
        case .sending, .codeSent, .verifying: true
        case .idle: false
        }
    }

    var locksEmail: Bool { self == .verifying }

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
