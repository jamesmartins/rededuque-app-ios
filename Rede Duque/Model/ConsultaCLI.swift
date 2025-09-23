//   let consultaCLI = try? JSONDecoder().decode(ConsultaCLI.self, from: jsonData)

import Foundation

// MARK: - ConsultaCLI
struct ConsultaCLI: Codable {
    let rdUserID, rdUserCompany: Int?
    let rdUserMail, rdUserName, rdUserpass: String?
    let rdUserType: Int?
    let rdTokenCelular, rdVersao: String?
    let cpf: Int?

    enum CodingKeys: String, CodingKey {
        case rdUserID = "RD_userId"
        case rdUserCompany = "RD_userCompany"
        case rdUserMail = "RD_userMail"
        case rdUserName = "RD_userName"
        case rdUserpass = "RD_userpass"
        case rdUserType = "RD_userType"
        case rdTokenCelular = "RD_TokenCelular"
        case rdVersao = "RD_Versao"
        case cpf = "CPF"
    }
}
