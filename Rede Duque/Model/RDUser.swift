//   let rDUser = try? JSONDecoder().decode(RDUser.self, from: jsonData)

import Foundation

// MARK: - RDUser
struct RDUser: Codable {
    let rdUserID: String?
    let rdUserCompany: Int?
    let rdUserMail, rdUserName, rdUserType, rdTokenCelular: String?
    let rdUserPlayerID, rdVersao: String?

    enum CodingKeys: String, CodingKey {
        case rdUserID = "RD_userId"
        case rdUserCompany = "RD_userCompany"
        case rdUserMail = "RD_userMail"
        case rdUserName = "RD_userName"
        case rdUserType = "RD_userType"
        case rdTokenCelular = "RD_TokenCelular"
        case rdUserPlayerID = "RD_User_Player_Id"
        case rdVersao = "RD_Versao"
    }
}
