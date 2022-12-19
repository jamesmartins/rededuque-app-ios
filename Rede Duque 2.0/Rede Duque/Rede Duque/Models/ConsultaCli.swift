//
//  ConsultaCli.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 18/12/22.
//

import Foundation

// MARK: - ConsultaCli
struct ConsultaCli: Codable {
    let rdTokenCelular, rdVersao, rdUserCompany, rdUserID, rdUserMail, rdUserName, rdUserType, rdUserpass: String

        enum CodingKeys: String, CodingKey {
            case rdTokenCelular = "RD_TokenCelular"
            case rdVersao = "RD_Versao"
            case rdUserCompany = "RD_userCompany"
            case rdUserID = "RD_userId"
            case rdUserMail = "RD_userMail"
            case rdUserName = "RD_userName"
            case rdUserType = "RD_userType"
            case rdUserpass = "RD_userpass"
        }
}
