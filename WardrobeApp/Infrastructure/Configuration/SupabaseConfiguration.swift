import Foundation

struct SupabaseConfiguration: Equatable, Sendable {
    enum Error: Swift.Error, Equatable {
        case invalidURL
        case missingPublishableKey
    }

    let url: URL
    let publishableKey: String

    static func load(from values: [String: Any] = Bundle.main.infoDictionary ?? [:]) throws -> Self {
        guard
            let rawURL = values["SupabaseURL"] as? String,
            let url = URL(string: rawURL),
            url.scheme == "https",
            url.host?.hasSuffix(".supabase.co") == true
        else {
            throw Error.invalidURL
        }

        guard
            let key = values["SupabasePublishableKey"] as? String,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw Error.missingPublishableKey
        }

        return Self(url: url, publishableKey: key)
    }
}
