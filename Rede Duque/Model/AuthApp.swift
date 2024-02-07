//
//  AuthApp.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 18/12/23.
//

import Foundation

// MARK: - AuthApp
struct AuthApp: Codable {
    let codCliente: String
    let auth: Bool
    let key, idU, idL, entidade: String
    let veiculos: [Veiculo]

    enum CodingKeys: String, CodingKey {
        case codCliente = "cod_cliente"
        case auth, key, idU, idL, entidade, veiculos
    }
}

// MARK: - Veiculo
struct Veiculo: Codable {
    let placas: String

    enum CodingKeys: String, CodingKey {
        case placas = "PLACAS"
    }
}
