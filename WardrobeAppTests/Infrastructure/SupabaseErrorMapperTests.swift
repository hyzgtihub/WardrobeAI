import Foundation
import Testing
@testable import YISU

@Suite("Supabase error mapper")
struct SupabaseErrorMapperTests {
    @Test(arguments: ["invalid_credentials"])
    func mapsInvalidCredentialCodes(_ code: String) {
        #expect(SupabaseErrorMapper.map(authCode: code) == .invalidCredentials)
    }

    @Test(arguments: ["user_already_exists", "email_exists"])
    func mapsDuplicateEmailCodes(_ code: String) {
        #expect(SupabaseErrorMapper.map(authCode: code) == .emailAlreadyRegistered)
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .networkConnectionLost])
    func mapsNetworkFailures(_ code: URLError.Code) {
        #expect(SupabaseErrorMapper.map(URLError(code)) == .networkUnavailable)
    }

    @Test
    func mapsMissingSingleRowToAccountDataUnavailable() {
        #expect(SupabaseErrorMapper.map(postgrestCode: "PGRST116") == .accountDataUnavailable)
    }

    @Test
    func mapsUnknownFailures() {
        #expect(SupabaseErrorMapper.map(TestFailure()) == .unknown)
        #expect(SupabaseErrorMapper.map(authCode: "future_auth_code") == .unknown)
    }
}

private struct TestFailure: Error {}
