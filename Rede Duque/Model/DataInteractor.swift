//
//  DataInteractor.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 13/12/23.
//

import SwiftUI

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
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                print("1 - Erro no Login - \(#function):\n\(error)\n")
                print("2 - Erro no Login - \(#function):\n\(error.localizedDescription)\n")
                DispatchQueue.main.async {
                    self.authAppkey = ""
                    self.authAppidU = ""
                    completion(.failure(error))
                }
            }
        }
    }
    
}
