import Foundation

enum DadosComprasAPI {
    static let url = "https://adm.bunker.mk/wsjson/dadoscompras.php"

    static func fetch(cpf: String, pagina: Int = 1, completion: @escaping (ResultAPI<DadosComprasResponse>) -> Void) {
        let digits = cpf.filter(\.isNumber)
        let parameters: [String: Any] = [
            "NUM_CGCECPF": digits,
            "pagina": pagina
        ]
        let headers = [
            "authorizationCode": AppSecrets.authorizationCode
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
