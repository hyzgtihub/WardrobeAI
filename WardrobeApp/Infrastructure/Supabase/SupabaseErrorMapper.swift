import Foundation
import Supabase

enum SupabaseErrorMapper {
    static func map(_ error: any Error) -> AccountError {
        if let urlError = error as? URLError {
            return map(urlError)
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            let code = URLError.Code(rawValue: nsError.code)
            return map(URLError(code))
        }

        if let authError = error as? AuthError {
            switch authError {
            case let .api(_, errorCode, _, _):
                return map(authCode: errorCode.rawValue)
            case .sessionMissing:
                return .invalidCredentials
            default:
                return .unknown
            }
        }

        if let postgrestError = error as? PostgrestError {
            return map(postgrestCode: postgrestError.code)
        }

        return .unknown
    }

    static func map(authCode: String) -> AccountError {
        switch authCode {
        case "invalid_credentials":
            .invalidCredentials
        case "user_already_exists", "email_exists":
            .emailAlreadyRegistered
        case "request_timeout":
            .networkUnavailable
        default:
            .unknown
        }
    }

    static func map(postgrestCode: String?) -> AccountError {
        postgrestCode == "PGRST116" ? .accountDataUnavailable : .unknown
    }

    private static func map(_ error: URLError) -> AccountError {
        switch error.code {
        case .notConnectedToInternet, .timedOut, .networkConnectionLost,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            .networkUnavailable
        default:
            .unknown
        }
    }
}
