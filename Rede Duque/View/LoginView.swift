//
//  LoginView.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 21/11/23.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    //MARK: - Vars
    @AppStorage("username") var username    = ""
    @AppStorage("password") var password    = ""
    @AppStorage("authAppkey") var authAppkey    = ""
    @AppStorage("authAppidU") var authAppidU    = ""
    //filds
    @State var usuario                      = ""
    @State var senha                        = ""
    @State var saveUser                     = true
    @State var novoLogin                    = true
    //alert error
    @State var userEmpy                     = false
    @State var passEmpy                     = false
    @State var erroFaceID                   = false
    @State var errorLogin                   = false
    @State var errorMessage                 = ""
    //destination
    @State var goToNovoMenu                 = false
    //loading
    @State var isLoading                    = false
    //Chamando WebViews
    @State var showWebView = false
    @State var destinationWebView = WebViewDestination.esqueciMinhaSenha
    //Focu para fechar o teclado
    @FocusState private var isTextFieldFocused: Bool
    //Variaveis referentes a mascaras CPF e CNPJ
    let maxCPFLength = 14
    let maxCNPJLength = 18
    
    
    //MARK: - Body
    var body: some View {
        NavigationStack{
            ZStack{
                if isLoading {
                    LoadingView(text:"Carregando...")
                        .zIndex(1.5)
                }
                VStack{
                    
                    Image("loginProfile")
                        .padding()
                    
                    TextField("Usuário", text: Binding(
                        get: { usuario },
                        set: { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            usuario = applyMask(filtered)
                            
                            if usuario.count <= maxCPFLength || usuario.count <= maxCNPJLength {
                                usuario = String(usuario.prefix(maxCPFLength))
                            }
                        }
                    ))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .focused($isTextFieldFocused)
                        .keyboardType(.numberPad)
                    
                    SecureField("Senha", text: $senha)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .autocapitalization(.none)
                        
                    
                    Toggle(isOn: $saveUser) {
                        Text("Manter informações de login")
                    }
                    .padding(.bottom)
                    
                    Button(action: {
                        if validateUsers() {
                            saveUserAndPassword(saveUser)
                            authFaceID()
                        }
                    }, label: {
                        Text("ENTRAR")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(Color("bcColor"))
                            .cornerRadius(4.0)
                            .font(Font.custom("Roboto-Black", size: 16))
                    })
                    .padding()
                    
                    Button {
                        destinationWebView = .esqueciMinhaSenha
                        showWebView = true
                    } label: {
                        Text("Esqueci minha senha")
                    }
                    .padding(.bottom,8)
                    
                    HStack{
                        Text("Não possui cadastro?")
                        Button {
                            destinationWebView = .cadastro
                            showWebView = true
                        } label: {
                            Text("Cadastre-se")
                        }
                    }
                    
                }
                .onTapGesture {
                    hideKeyboard()
                }
                .zIndex(1.0)
                .padding()
                .navigationTitle("Faça seu login")
                .toolbarBackground(Color("bcColor"), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .fullScreenCover(isPresented: $showWebView){
                    WebView(url: DataInteractor.getURL(destinationWebView)) { errorDescription in
                        print(errorDescription)
                    }
                }
                .onAppear{
                    self.usuario = username
                    self.senha   = password
                    DispatchQueue.main.async{
                        authFaceID(true)
                    }
                }
                .alert("Informe o usuário corretamente!", isPresented: $userEmpy ) {
                    Button("OK", role: .cancel) {
                        userEmpy = false
                    }
                }
                .alert("Informe a senha corretamente!", isPresented: $passEmpy ) {
                    Button("OK", role: .cancel) {
                        passEmpy = false
                    }
                }
                .alert("Erro ao validar o Face ID!", isPresented: $erroFaceID ) {
                    Button("OK", role: .cancel) {
                        erroFaceID = false
                    }
                }
                .alert("Erro no Login!\n\(errorMessage)", isPresented: $errorLogin ) {
                    Button("OK", role: .cancel) {
                        errorLogin = false
                        errorMessage = ""
                    }
                }
            }
        }
    }
    
    //MARK: - Validadando campos
    func validateUsers(_ showError: Bool = true)-> Bool {
        if self.usuario.isEmpty {
            if showError {
                userEmpy = true
            }
            return false
        } else if self.senha.isEmpty {
            if showError {
                passEmpy = true
            }
            return false
        } else {
            return true
        }
    }
    
    //MARK: - Salvando Usuario e Senha
    func saveUserAndPassword(_ saveData: Bool){
        if saveData {
            if username == usuario &&
                password == senha {
                self.novoLogin = authAppkey.isEmpty && authAppidU.isEmpty
            } else {
                self.username = self.usuario
                self.password = self.senha
                self.novoLogin = true
            }
        } else {
            self.novoLogin = true
            self.username = ""
            self.password = ""
        }
    }
    
    //MARK: - FaceID
    func authFaceID(_ firstTime: Bool = false){
        let context = LAContext()
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: .none) {

            guard validateUsers(!firstTime) else { return }

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Validação de seguraça") { success, error in
                if success {
                    login()
                } else {
                    erroFaceID = true
                }
            }
            
        } else {
            guard validateUsers() else { return }
            guard !firstTime else {return}
            
            login()
        }
        
    }
    
    //MARK: - Login
    func login(){
        dump("login!")
        isLoading = true
        if !self.novoLogin {
            print("Login sem request realizado com sucesso!")
            isLoading = false
            destinationWebView = .novoMenu
            showWebView = true
            return
        }
        DataInteractor.shared.login(user: self.extractNumbers(from: self.usuario), password: self.senha) { result in
            switch result{
            case .success():
                DispatchQueue.main.async{
                    print("Login realizado com sucesso!")
                    isLoading = false
                    destinationWebView = .novoMenu
                    showWebView = true
                }
            case .failure(let error):
                DispatchQueue.main.async{
                    print("erro no login: "+error.localizedDescription)
                    isLoading = false
                    errorLogin = true
                    
                    if !error.localizedDescription.contains("The request timed out.") {
                        errorMessage = "Usuário e/ou senha estão errados!"
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    //MARK: - Fechando o teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isTextFieldFocused = false
    }
    
    //MARK: - Mascara CPF ou CNPJ
    private func applyMask(_ text: String) -> String {
        var formattedText = ""
        let cpfLength = 11
        
        for i in 0..<text.count {
            if i < cpfLength {
                formattedText.append(text[text.index(text.startIndex, offsetBy: i)])
                if i == 2 || i == 5 {
                    formattedText.append(".")
                } else if i == 8 {
                    formattedText.append("-")
                }
            } else {
                formattedText.append(text[text.index(text.startIndex, offsetBy: i)])
                if i == 1 || i == 4 {
                    formattedText.append(".")
                } else if i == 7 {
                    formattedText.append("/")
                } else if i == 11 {
                    formattedText.append("-")
                }
            }
        }
        
        return formattedText
    }

    private func extractNumbers(from input: String) -> String {
        let numbersOnly = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return numbersOnly
    }
}

#Preview {
    LoginView()
}
