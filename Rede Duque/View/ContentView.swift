//
//  ContentView.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 19/11/23.
//

import SwiftUI

struct ContentView: View {
    
    let heightButton = 46.0
    var apiMain : APIMain? = nil
    @State var isLoading = false
    @State var erroRequest = false
    //Chamando WebViews
    @State var showWebView = false
    @State var destinationWebView = WebViewDestination.cadastro
    
    var body: some View {
        NavigationStack{
            ZStack{
                if isLoading {
                    LoadingView(text:"Carregando...")
                        .zIndex(1.5)
                }
                VStack{
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .padding(.vertical, 30)
                    
                    NavigationLink {
                        LoginView()
                    } label: {
                        button("LOGIN", login: true)
                    }
                    
                    Button{
                        showWebView = true
                        destinationWebView = .cadastro
                    } label: {
                        button("CADASTRE-SE")
                    }
                    
                    Button{
                        showWebView = true
                        destinationWebView = .faleConosco
                    } label: {
                        button("FALE CONOSCO")
                    }
                    
                    Button{
                        showWebView = true
                        destinationWebView = .parceiro
                    } label: {
                        button("SEJA NOSSO PARCEIRO")
                    }
                    
                    Spacer()
                }
                .zIndex(1.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("bcColor"))
                .navigationTitle("")
                .refreshable {
                    //fetchData()
                }
                .task {
                    //fetchData()
                }
                .alert("Erro no Request\nTente novamente!", isPresented: $erroRequest) {
                    Button("OK", role: .cancel) {
                        //fetchData()
                    }
                }
                .fullScreenCover(isPresented: $showWebView){
                    WebView(url: DataInteractor.getURL(destinationWebView)) { errorDescription in
                        print(errorDescription)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func button(_ text: String,login: Bool = false) -> some View {
        if login {
            Text(text)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: heightButton)
                .background(Color("bcColor"))
                .cornerRadius(heightButton / 2)
                .shadow(radius: 3, y: 5)
                .font(Font.custom("Roboto-Black", size: 16))
                .padding(.horizontal)
        } else {
            Text(text)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: heightButton)
                .background(Color("bcColor"))
                .font(Font.custom("Roboto-Black", size: 16))
                .padding(.horizontal)
        }
    }

    
    
    func fetchData(){
        isLoading = true
        DataInteractor.shared.fetchData { result in
            switch result {
            case .success():
                isLoading = false
            case .failure(let error):
                print(error.localizedDescription)
                isLoading = false
                erroRequest = true
            }
        }
    }
    
}

#Preview {
    ContentView()
}
