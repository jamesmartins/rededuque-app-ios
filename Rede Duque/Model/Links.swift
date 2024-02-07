//
//  Links.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 18/12/23.
//

import Foundation

enum Links: String {
    case cadastro = "consulta_V2.do?key=c2dYUmt3RllSZmvCog==&t=SzwrGPtfs£s£UXRLKgEsQ6mDRkKtMIiTcG"
    case faleConosco = "faleConosco.do?key=c2dYUmt3RllSZmvCog==&t=SzwrGPtfs£s£UXRLKgEsQ6mDRkKtMIiTcG"
    case parceiro = "parceiro.do?key=c2dYUmt3RllSZmvCog==&t=SzwrGPtfs£s£UXRLKgEsQ6mDRkKtMIiTcG"
    case esqueciMinhaSenha = "recuperacaoSenha.do?key=sgXRkwFYRfk¢&t=vctlcPJ7SeoXRLKgEsQ6mHrhO0zwUM0s£&cpf="
    case login = "https://adm.bunkerapp.com.br/wsjson/authApp.do"
    case novoMenu = "novoMenu.do?key="
    case intro = "intro.do?key=c2dYUmt3RllSZmvCog==&t=XgqGQ8h2mcoDrGsxcOEdHAdXO3s%C2%A3B1QY4"
    
    var url: URL {
        let baseURL = "https://adm.bunkerapp.com.br/app/"
        
        if self == .novoMenu {
            
            var key = ""
            var idU = ""
            
            if DataInteractor.shared.authAppkey == "" || DataInteractor.shared.authAppidU == "" {
                guard let authApp = DataInteractor.shared.authApp else {
                    print("Erro ao obter Link: direcionando para o google")
                    return URL(string: "https://www.google.com.br/")!
                }
                key = authApp.key
                idU = authApp.idU
            } else {
                key = DataInteractor.shared.authAppkey
                idU = DataInteractor.shared.authAppidU
            }
            
            //let urlString = "https://adm.bunkerapp.com.br/app/teste.do?key=" + key + "&idU=" + idU + "&cds=0"
            let urlString = "https://adm.bunkerapp.com.br/app/novoMenu.do?key=" + key + "&idU=" + idU + "&cds=0"
            
            if let url = URL(string: urlString) {
                print("Link obtido:\(url.absoluteString)")
                return url
            } else {
                print("Erro ao obter Link: direcionando para o google")
                return URL(string: "https://www.google.com.br/")!
            }
        } else {
            if let url = URL(string:baseURL + self.rawValue) {
                print("Link obtido:\(url.absoluteString)")
                return url
            } else {
                print("Erro ao obter Link: direcionando para o google")
                return URL(string: "https://www.google.com.br/")!
            }
        }
    }
}
