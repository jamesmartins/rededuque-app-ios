import Foundation

enum DadosComprasAPI {
    static let url = "https://adm.bunker.mk/wsjson/dadoscompras.php"

    private static var authorizationCode: String {
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

    static func fetch(cpf: String, pagina: Int = 1, completion: @escaping (ResultAPI<DadosComprasResponse>) -> Void) {
        let digits = cpf.filter(\.isNumber)
        let parameters: [String: Any] = [
            "NUM_CGCECPF": digits,
            "pagina": pagina
        ]
        let headers = [
            "authorizationCode": authorizationCode
        ]

        Service.shared.request(
            url,
            method: .POST,
            parameters: parameters,
            headers: headers,
            completion: completion
        )
    }
}
