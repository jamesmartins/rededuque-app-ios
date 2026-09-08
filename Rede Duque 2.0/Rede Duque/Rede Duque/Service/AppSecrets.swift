import Foundation

enum AppSecrets {
    static var authorizationCode: String {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
            let code = dict["authorizationCode"] as? String,
            !code.isEmpty,
            code != "REPLACE_WITH_AUTHORIZATION_CODE"
        else {
            assertionFailure("Missing Secrets.plist. Copy Secrets.example.plist to Secrets.plist and set authorizationCode.")
            return ""
        }
        return code
    }

    /// APP.do sample uses Base64 with padding (`==`).
    static var authorizationCodePadded: String {
        let value = authorizationCode
        let remainder = value.count % 4
        guard remainder != 0 else { return value }
        return value + String(repeating: "=", count: 4 - remainder)
    }
}
