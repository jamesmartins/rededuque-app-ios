//
//  TokenOneSignal.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 18/12/22.
//

import Foundation

// MARK: - TokenOneSignal
struct TokenOneSignal: Codable {
    let errors: [ErrorResult]
}

// MARK: - Error
struct ErrorResult: Codable {
    let message: String
}
