//
//  Service.swift
//  EduAdventista
//
//  Created by Leonardo Modro on 08/06/20.
//  Copyright © 2020 Casa Publicadora Brasileira. All rights reserved.
//

import UIKit

//MARK: - Typealiases
typealias ResultAPI<T: Decodable> = Result<T, ErrorTypes>

enum HttpMethod: String {
    case  GET
    case  POST
    case  DELETE
    case  PUT
}

final class Service {
    
    static let shared = Service()
    
    var session : URLSession?
    var request : URLRequest?
    
    func request<T: Decodable>(_ path: String, method: HttpMethod = .GET, parameters: [String: Any]? = nil,  completion: @escaping (ResultAPI<T>) -> Void) {
        
        guard let url = URL(string: path) else {
            completion(.failure(ErrorTypes.invalidURL))
            return
        }
        
        request = URLRequest(url: url)
        
        if let params = parameters {
            
            let  jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            
            request!.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request!.httpBody = jsonData
        }
        
        request!.httpMethod = method.rawValue
        
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 99
        configuration.timeoutIntervalForResource = 99
        
        session = URLSession(configuration: configuration)
        
        if session == nil {
            completion(.failure(.invalidCredentials))
            return
        }
        
        session!.dataTask(with: request!) { data, response, error in
            DispatchQueue.main.async {
                
                if error != nil {
                    print("Error request: ", error!.localizedDescription)
                    completion(.failure(ErrorTypes.requestFailed))
                    return
                }
                
                if let data = data {
                     if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                         
                         let str = String(decoding: data, as: UTF8.self)
                         print(str)
                         
                         if T.self == ConsultaCli.self {
                             if let result = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                                 
                                 print(result)
                                 
                                 let rdTokenCelular = result["RD_TokenCelular"] as? String == nil ? "" : result["RD_TokenCelular"] as! String
                                 
                                 let rdVersao = result["RD_Versao"] as? String == nil ? "" : result["RD_Versao"] as! String
                                 
                                 let rdUserCompany = "19"
                                 
                                 let rdUserID = "\(result["RD_userId"] ?? "")"
                                 
                                 let rdUserMail = "\(result["RD_userMail"] ?? "")"
                                 
                                 let rdUserName = "\(result["RD_userName"] ?? "")"
                                 
                                 let rdUserType = "\(result["RD_userType"] ?? "")"
                                 
                                 let rdUserpass = "\(result["RD_userpass"] ?? "")"
                                 
                                 
                                 let object = ConsultaCli(rdTokenCelular: rdTokenCelular, rdVersao: rdVersao, rdUserCompany: rdUserCompany, rdUserID: rdUserID, rdUserMail: rdUserMail, rdUserName: rdUserName, rdUserType: rdUserType, rdUserpass: rdUserpass)
                                 
                                 completion(.success(object as! T))
                                 return
                             }
                         }
                         
                         if let object = try? JSONDecoder().decode(T.self, from: data) {
                             completion(.success(object))
                             return
                         } else {
                             print(error?.localizedDescription)
                             completion(.failure(ErrorTypes.failedDecodingJSON))
                             return
                         }
                         
                     } else {
                         completion(.failure(.invalidCredentials))
                     }
                } else {
                    completion(.failure(ErrorTypes.failedDecodingJSON))
                    return
                }
            }
        }.resume()
    }
    
}

//MARK: - ErrorTypes

enum ErrorTypes: Error {
    case invalidCredentials
    case uploadImageFailed
    case saveImageFailed
    case uploadFailed
    case invalidURL
    case pushNotificationFailed
    case downloadFailed
    case unknownError
    case unwrapDataFailed
    case requestFailed
    case failedDecodingJSON
    case answerError
    case calculateRouteFailed
    case deleteFileFailed
    case voucherUsed
    
    var description: String {
        switch self {
        case .invalidCredentials:
            return "Usuário ou senha incorretos, tente novamente"
        case .uploadImageFailed:
            return "Ocorreu um erro ao tentar fazer upload da imagem, tente novamente"
        case .saveImageFailed:
            return "Ocorreu um erro ao tentar salvar a imagem, tente novamente"
        case .uploadFailed:
            return "Ocorreu um erro ao tentar fazer upload, tente novamente"
        case .invalidURL:
            return "URL inválida"
        case .pushNotificationFailed:
            return "Ocorreu um erro ao tentar enviar a notificação"
        case .downloadFailed:
            return "Ocorreu um erro ao tentar baixar o arquivo, tente novamente"
        case .unknownError:
            return "Ocorreu algum erro ao tentar prosseguir, tente novamente"
        case .unwrapDataFailed:
            return "Erro ao tentar pegar dados do request"
        case .requestFailed:
            return "Erro ao tentar buscar dados"
        case .failedDecodingJSON:
            return "Erro ao tentar obter alguns dados"
        case .answerError:
            return "Ocorreu algum problema ao salvar a resposta."
        case .calculateRouteFailed:
            return "Ocorreu um erro ao calcular a rota para a escola. Tente novamente"
        case .deleteFileFailed:
            return "Ocorreu um erro ao tentar apagar o arquivo. Tente novamente"
        case .voucherUsed:
            return "Este voucher já foi resgatado! Tente com outro voucher!"
        }
    }
}
