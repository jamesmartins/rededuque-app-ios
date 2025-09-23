//
//  DataInteractor.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 13/12/23.
//

import SwiftUI
import OneSignalFramework

class DataInteractor {
    
    //MARK: - Vars
    @AppStorage("authAppkey") var authAppkey    = ""
    @AppStorage("authAppidU") var authAppidU    = ""
    
    private init() {}
    static var shared = DataInteractor()
    
    var apiMain : APIMain?
    var authApp: AuthApp?
    
    static func getURL(_ destinationWebView: WebViewDestination) -> URL {
        var url : URL
        switch destinationWebView {
        case .cadastro:
            url = Links.cadastro.url
        case .faleConosco:
            url = Links.faleConosco.url
        case .parceiro:
            url = Links.parceiro.url
        case .esqueciMinhaSenha:
            url = Links.esqueciMinhaSenha.url
        case .novoMenu:
            url = Links.novoMenu.url
        }
        return url
    }
    
    func fetchData(completion: @escaping (Result<Void, Error>) -> Void) {
        let apiManager = APIManager()
        Task {
            do {
                let data : APIMain = try await apiManager.performRequest(urlString: "https://adm.bunkerapp.com.br/wsjson/APP.do", method: .post(body: [:]))
                self.apiMain = data
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                print("Erro no request - \(#function):\n\(error.localizedDescription)\n")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func login(user: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let apiManager = APIManager()
        self.authAppkey = ""
        self.authAppidU = ""
        self.authApp = nil
        Task {
            do {
                let param : [String:Any] = [ "CPF":user , "SENHA":password]
                let data : AuthApp = try await apiManager.performRequest(urlString: Links.login.rawValue, method: .post(body: param))
                self.authApp = data
                self.authAppkey = self.authApp?.key ?? ""
                self.authAppidU = self.authApp?.idU ?? ""
                
                consultaCli(idU: self.authAppidU) { result in
                    switch result{
                    case .success():
                        DispatchQueue.main.async {
                            completion(.success(()))
                        }
                    case .failure(let error):
                        print("Erro no consultaCli: \(error.localizedDescription)\n")
                        print("Login em andamento.")
                        DispatchQueue.main.async {
                            completion(.success(()))
                        }
                    }
                }
                
                
            } catch {
                print("1 - Erro no Login - \(#function):\n\(error)\n")
                print("2 - Erro no Login - \(#function):\n\(error.localizedDescription)\n")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func consultaCli(idU: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let apiManager = APIManager()
                
                var paramBase64 : String = ""
                if let data = idU.data(using: .utf8) {
                    paramBase64 = data.base64EncodedString()
                }
                
                let param : [String:Any] = ["RD_userId" : paramBase64 , "RD_userCompany" : 19]
                let data : ConsultaCLI = try await apiManager.performRequest(urlString: Links.consultaCli.rawValue, method: .post(body:param))
                
                var user = RDUser(rdUserID: data.rdUserID?.description,
                                  rdUserCompany: data.rdUserCompany,
                                  rdUserMail: data.rdUserMail,
                                  rdUserName: data.rdUserName,
                                  rdUserType: data.rdUserType?.description,
                                  rdTokenCelular: OneSignal.User.pushSubscription.token,
                                  rdUserPlayerID: OneSignal.User.pushSubscription.id,
                                  rdVersao: "iOS")
                
                if let userParam = toDictionary(user) {
                    let rd : RDUser = try await apiManager.performRequest(urlString: Links.tokenApp.rawValue, method: .post(body:userParam))
                }
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                print("Erro no consultaCli: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    
    func toDictionary<T: Codable>(_ codableObject: T) -> [String: Any]? {
        do {
            let jsonData = try JSONEncoder().encode(codableObject)
            if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any] {
                return dictionary
            }
        } catch {
            print("Erro ao converter para dicionário: \(error)")
        }
        return nil
    }
    
}
