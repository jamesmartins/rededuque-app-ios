import Foundation

enum AppConfigAPI {
    static let url = "https://adm.bunkerapp.com.br/wsjson/APP.do"

    static func fetch(completion: @escaping (ResultAPI<AppConfigResponse>) -> Void) {
        let headers = [
            "authorizationCode": AppSecrets.authorizationCodePadded
        ]

        Service.shared.request(
            url,
            method: .GET,
            headers: headers,
            completion: completion
        )
    }
}
