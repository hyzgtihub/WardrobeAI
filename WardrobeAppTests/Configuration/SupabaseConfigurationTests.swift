import Foundation
import Testing
@testable import YISU

@Suite("Supabase configuration")
struct SupabaseConfigurationTests {
    @Test
    func loadsValidValues() throws {
        let configuration = try SupabaseConfiguration.load(from: [
            "SupabaseURL": "https://project.supabase.co",
            "SupabasePublishableKey": "publishable-test-key-1234567890"
        ])

        #expect(configuration.url.absoluteString == "https://project.supabase.co")
        #expect(configuration.publishableKey == "publishable-test-key-1234567890")
    }

    @Test(arguments: ["", "https:", "http://project.supabase.co", "not-a-url"])
    func rejectsInvalidURL(value: String) {
        #expect(throws: SupabaseConfiguration.Error.invalidURL) {
            try SupabaseConfiguration.load(from: [
                "SupabaseURL": value,
                "SupabasePublishableKey": "publishable-test-key-1234567890"
            ])
        }
    }

    @Test
    func rejectsMissingKey() {
        #expect(throws: SupabaseConfiguration.Error.missingPublishableKey) {
            try SupabaseConfiguration.load(from: [
                "SupabaseURL": "https://project.supabase.co"
            ])
        }
    }
}
