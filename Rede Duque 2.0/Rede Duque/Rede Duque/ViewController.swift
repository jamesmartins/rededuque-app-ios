//
//  ViewController.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 01/08/22.
//

import UIKit
import WebKit
import NVActivityIndicatorView
import OneSignalFramework
import LocalAuthentication

class ViewController: UIViewController {
    //MARK: - VARS
    static let dev =  false
    let appURL = URL(string: "https://adm.bunkerapp.com.br/app/intro.do?key=sgXRkwFYRfk\(ViewController.dev ? "&dev=true" : "")")!
    //let appURL = URL(string: "https://adm.bunkerapp.com.br/app/app.do?key=c2dYUmt3RllSZmvCog==&dev=true")!
    var webView: WKWebView!
    var indicator = NVActivityIndicatorView(frame: .zero)
    private var isNativeHomePresented = false
    private var isPresentingNativeHome = false
    
    //MARK: - INIT
    override func loadView() {
        super.loadView()
        setupWebView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLoadingIndicator()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupData()
    }


    //MARK: - Setup
    func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let contentController = configuration.userContentController
        contentController.add(self, name: "cpfCapture")
        contentController.addUserScript(WKUserScript(
            source: Self.cpfCaptureJavaScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = UIColor.black
        view = webView
        view.backgroundColor = UIColor.black
    }
    
    func setupData() {
        webView.load(URLRequest(url: appURL))
    }
    
    func setupLoadingIndicator() {
        let indicatorFrame = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))
        indicator = NVActivityIndicatorView(frame: indicatorFrame, type: .circleStrokeSpin)
        indicator.center = self.view.center
        indicator.color = .gray
        self.webView.addSubview(indicator)
        //indicator.startAnimating()
        print(#function,"startAnimating")
    }
}

extension ViewController: WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "cpfCapture" else { return }
        if let value = message.body as? String {
            _ = persistCPFIfValid(value)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !indicator.isAnimating {
            DispatchQueue.main.async {
                self.indicator.startAnimating()
            }
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
        }
        
        
        
        let url = webView.url!.absoluteString
        dump("URL:" + url)
        
        if url.contains("app.do") && url.contains("idL="){
            dump("segunda passagem")
            
            let context = LAContext()
            var error : NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                
                let reason = "Autentique para realizar o login"
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            self.indicator.startAnimating()
                        }
                        webView.evaluateJavaScript("login()") { anyResult, error in
                            if error != nil {
                                DispatchQueue.main.async {
                                    self.indicator.stopAnimating()
                                }
                            }
                            dump(anyResult ?? "sem retorno")
                        }
                    }
                }
                
            } else {
                dump("autenticação indisponivel")
            }
            
        } else if url.contains("app.do") && !url.contains("idL="){

            dump("primeira passagem")
            
            if let idl = get("idL") as? String {
                
                webView.stopLoading()
                let urlString = url+"&"+idl
                dump("Url modificada:"+urlString)
                let link = URL(string: urlString)!
                let request = URLRequest(url:link)
                webView.load(request)
            }
        } else if url.contains("idL=") && !url.contains("app.do") {
            dump("apos o login")
            
            var idL = url.substring(from: url.range(of: "idL=")!.upperBound)
            idL = "idL="+idL
            dump("Logado\nidL:\(idL)")
        
            set("idL", idL)
            captureAndPersistCPFFromWebView(completion: nil)
            
            let context = LAContext()
            var error : NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                dump("autenticação ok")
            } else {
                dump("autenticação indisponivel")
            }
            
        } else if url.contains("novoMenu") && !url.contains("idL=") {
            // Only drop the session token — keep CPF/login for dadoscompras / Face ID.
            clear("idL")
        }
        
        dump("fim")
        
        if (webView.url?.description ?? "").contains("novoMenu"){
            
            let url = webView.url!.absoluteString
            if url.contains("idU=") {
                var userID = url.substring(from: url.range(of: "idU=")!.upperBound)
                userID = userID.replacingOccurrences(of: "&log=1", with: "")
                userID = userID.removingPercentEncoding ?? userID
                userID = userID.toBase64()
                
                dump("Logado\nUserID:\(userID)")
                
                self.randlerConsultaCli(userID: userID)
            }

            if !self.isNativeHomePresented && !self.isPresentingNativeHome {
                self.isPresentingNativeHome = true
                self.presentNativeHomeWhenCPFReady()
            }
            
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
        }
    }
    
    //MARK: - FUNCS

    func presentNativeHomeWhenCPFReady(attempt: Int = 0) {
        captureAndPersistCPFFromWebView { [weak self] in
            guard let self = self else { return }
            if self.storedCPF() != nil || attempt >= 4 {
                self.showNativeHome(userName: self.getString("userName") ?? "Cliente")
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.presentNativeHomeWhenCPFReady(attempt: attempt + 1)
            }
        }
    }

    func showNativeHome(userName: String) {
        isNativeHomePresented = true
        isPresentingNativeHome = false
        let cpf = storedCPF()
        let viewModel = HomeViewModel(userName: userName, cpf: cpf)
        viewModel.onBack = { [weak self] in
            self?.dismissNativeHome()
        }
        viewModel.onGenerateToken = {
            print("Home: Gerar Token")
        }
        viewModel.onMenuItem = { [weak self] item in
            if item == .logout {
                self?.performLogout()
            } else {
                print("Home menu:", item.rawValue)
            }
        }
        viewModel.onRedeemed = {
            print("Home: Resgatado")
        }
        viewModel.onExpired = {
            print("Home: Expirado")
        }

        let home = HomeViewController(viewModel: viewModel)
        home.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(home, animated: true)
            viewModel.loadHome()
        }
    }

    func dismissNativeHome() {
        isNativeHomePresented = false
        isPresentingNativeHome = false
        dismiss(animated: true)
    }

    func updateNativeHome(userName: String) {
        if let home = presentedViewController as? HomeViewController {
            // Keep `primeiro_nome` from dadoscompras; only fill name if still placeholder.
            if !home.viewModel.didResolveNameFromAPI {
                home.viewModel.applyUserName(userName)
            }
            if let cpf = storedCPF() {
                let hadMissingCPF = home.viewModel.cpf == nil
                home.viewModel.cpf = cpf
                if hadMissingCPF {
                    home.viewModel.loadHome()
                }
            }
        }
    }

    /// Returns persisted CPF digits when valid (10–11).
    func storedCPF() -> String? {
        for key in ["cpf", "login"] {
            guard let raw = getString(key) else { continue }
            let digits = raw.filter(\.isNumber)
            if (10...11).contains(digits.count) {
                return digits
            }
        }
        return nil
    }

    func performLogout() {
        clearSessionCredentials()
        isNativeHomePresented = false
        isPresentingNativeHome = false
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.webView.load(URLRequest(url: self.appURL))
        }
    }

    func clearSessionCredentials() {
        clear("idL")
        clear("cpf")
        clear("login")
        clear("senha")
        clear("userName")
    }

    /// Persists CPF digits when the value looks like a Brazilian CPF (10–11 digits).
    @discardableResult
    func persistCPFIfValid(_ raw: String?) -> Bool {
        guard let raw = raw else { return false }
        let digits = raw.filter(\.isNumber)
        guard (10...11).contains(digits.count), digits != "true" else { return false }
        set("cpf", digits)
        set("login", digits)
        return true
    }

    func captureAndPersistCPFFromWebView(completion: (() -> Void)?) {
        if storedCPF() != nil {
            completion?()
            return
        }

        let group = DispatchGroup()

        group.enter()
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            defer { group.leave() }
            guard let self = self else { return }
            for cookie in cookies {
                let name = cookie.name.lowercased()
                if name.contains("login") || name.contains("cpf") || name.contains("cgce") || name.contains("usuario") {
                    if self.persistCPFIfValid(cookie.value) { return }
                }
            }
            // Fallback: any cookie whose value looks like a CPF.
            for cookie in cookies {
                if self.persistCPFIfValid(cookie.value) { return }
            }
        }

        group.enter()
        let js = """
        (function() {
          var out = [];
          function push(v){ if(v!=null && String(v).length) out.push(String(v)); }
          try {
            ['login','cpf','NUM_CGCECPF','num_cgcecpf','usuario','user','documento'].forEach(function(k){
              push(window.localStorage.getItem(k));
              push(window.sessionStorage.getItem(k));
            });
          } catch (e) {}
          try {
            var parts = (document.cookie || '').split(';');
            for (var i = 0; i < parts.length; i++) {
              var kv = parts[i].split('=');
              if (kv.length >= 2) push(decodeURIComponent(kv.slice(1).join('=').trim()));
            }
          } catch (e) {}
          try {
            document.querySelectorAll('input').forEach(function(el){
              var n = ((el.name||'') + ' ' + (el.id||'') + ' ' + (el.placeholder||'') + ' ' + (el.type||'')).toLowerCase();
              if (n.indexOf('cpf') >= 0 || n.indexOf('login') >= 0 || n.indexOf('usuario') >= 0 || n.indexOf('documento') >= 0 || n.indexOf('tel') >= 0) {
                push(el.value);
              } else if (el.value && String(el.value).replace(/\\D/g,'').length >= 10) {
                push(el.value);
              }
            });
          } catch (e) {}
          return out.join('|');
        })();
        """
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            defer { group.leave() }
            guard let self = self else { return }
            if let blob = result as? String {
                for part in blob.split(separator: "|") {
                    if self.persistCPFIfValid(String(part)) { break }
                }
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    private static let cpfCaptureJavaScript = """
    (function() {
      if (window.__redeDuqueCpfCaptureInstalled) { return; }
      window.__redeDuqueCpfCaptureInstalled = true;
      function digits(v){ return String(v||'').replace(/\\D/g,''); }
      function send(v){
        var d = digits(v);
        if (d.length < 10 || d.length > 11) { return; }
        try {
          window.webkit.messageHandlers.cpfCapture.postMessage(d);
        } catch (e) {}
      }
      function scan(){
        try {
          ['login','cpf','NUM_CGCECPF','num_cgcecpf','usuario','user','documento'].forEach(function(k){
            send(window.localStorage.getItem(k));
            send(window.sessionStorage.getItem(k));
          });
        } catch (e) {}
        try {
          var parts = (document.cookie || '').split(';');
          for (var i = 0; i < parts.length; i++) {
            var kv = parts[i].split('=');
            if (kv.length >= 2) send(decodeURIComponent(kv.slice(1).join('=').trim()));
          }
        } catch (e) {}
        try {
          document.querySelectorAll('input').forEach(function(el){ send(el.value); });
        } catch (e) {}
      }
      document.addEventListener('submit', function(){ setTimeout(scan, 0); }, true);
      document.addEventListener('change', function(e){
        if (e && e.target) { send(e.target.value); }
      }, true);
      document.addEventListener('input', function(e){
        if (e && e.target) { send(e.target.value); }
      }, true);
      setTimeout(scan, 300);
      setTimeout(scan, 1000);
    })();
    """
    func randlerCookies(cookies: [HTTPCookie]){
        
        if cookies.count != 2 {return}
        let login = cookies[0]
        let senha = cookies[1]
        
        //print(login.value,senha.value)
        
        if get("senha") == nil && get("login") == nil {
            
            if login.value != "true" && senha.value != "true" {
                set("senha", senha.value)
                set("login", login.value)
            } else {
                
                var loginProperties : [HTTPCookiePropertyKey: Any] = [:]
                for (properti, sValue) in login.properties! {
                    if properti.rawValue.lowercased() == "value" {
                        loginProperties[properti] = "TesteLogin"
                    } else {
                        loginProperties[properti] = sValue
                    }
                }
                let newLogin = HTTPCookie(properties: loginProperties)
                
                var senhaProperties : [HTTPCookiePropertyKey: Any] = [:]
                for (properti, sValue) in senha.properties! {
                    if properti.rawValue.lowercased() == "value" {
                        senhaProperties[properti] = "TesteSenha"
                    } else {
                        senhaProperties[properti] = sValue
                    }
                }
                let newSenha = HTTPCookie(properties: senhaProperties)
                
                
                self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(newLogin!)
                //self.webView.configuration.websiteDataStore.httpCookieStore.delete(login)
                
                self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(newSenha!)
                //self.webView.configuration.websiteDataStore.httpCookieStore.delete(senha)
            }
        } else {
            guard let senhaString = get("senha") as? String else {return}
            guard let loginString = get("login") as? String else {return}
            
            var loginProperties : [HTTPCookiePropertyKey: Any] = [:]
            for (properti, sValue) in login.properties! {
                if properti.rawValue.lowercased() == "value" {
                    loginProperties[properti] = loginString
                } else {
                    loginProperties[properti] = sValue
                }
            }
            let newLogin = HTTPCookie(properties: loginProperties)
            
            var senhaProperties : [HTTPCookiePropertyKey: Any] = [:]
            for (properti, sValue) in senha.properties! {
                if properti.rawValue.lowercased() == "value" {
                    senhaProperties[properti] = senhaString
                } else {
                    senhaProperties[properti] = sValue
                }
            }
            let newSenha = HTTPCookie(properties: senhaProperties)
            
            
            self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(newLogin!)
            //self.webView.configuration.websiteDataStore.httpCookieStore.delete(login)
            
            self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(newSenha!)
            //self.webView.configuration.websiteDataStore.httpCookieStore.delete(senha)
        }
    }
    func randlerConsultaCli(userID: String){
        let param : [String : Any] = ["RD_userId": userID, "RD_userCompany": 19]
        //print(param)
        
        let path = "https://adm.bunkerapp.com.br/wsjson/ConsultaCli.do"
        
        Service.shared.request(path, method: .POST, parameters: param) { (result: Result<ConsultaCli, ErrorTypes>) in
            
            switch result {
            case .failure(let err):
                print("Error token: ", err)
            case .success(let resp):
                print("Successfully saved token:\n", resp)
                self.set("userName", resp.rdUserName)
                self.updateNativeHome(userName: resp.rdUserName)
                self.randlerTokenOneSignal(resp)
            }
            
        }
    }
    
    func randlerTokenOneSignal(_ cli: ConsultaCli){
        let pushSubscription = OneSignal.User.pushSubscription
        guard let token = pushSubscription.token else { return }
        guard let userId = pushSubscription.id else { return }

        print(cli)

        let param: [String: Any] = [
            "RD_userId": cli.rdUserID,
            "RD_userCompany": cli.rdUserCompany,
            "RD_userMail": cli.rdUserMail,
            "RD_userName": cli.rdUserName,
            "RD_userType": cli.rdUserType,
            "RD_TokenCelular": token,
            "RD_Versao": "iOS",
            "RD_User_Player_Id": userId
        ]

        print(param)

        let path = "https://adm.bunker.mk/wsjson/TokenAppPush.do"

        Service.shared.request(path, method: .POST, parameters: param) { (result: Result<TokenOneSignal, ErrorTypes>) in
            switch result {
            case .failure(let err): print("Error token: ", err)
            case .success(let resp): print("Successfully saved token:", resp)
            }
        }
    }
}

//MARK: - WebView

extension WKWebView {

    private var httpCookieStore: WKHTTPCookieStore  { return WKWebsiteDataStore.default().httpCookieStore }

    func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->())  {
        var cookieDict = [String : AnyObject]()
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                } else {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
    
    func getCookie(completion: @escaping ( ([HTTPCookie]) -> ()) ){
        httpCookieStore.getAllCookies { cookies in
            var cookieArray = [HTTPCookie]()
            for cookie in cookies {
                if cookie.name == "login" || cookie.name == "senha" {
                    cookieArray.append(cookie)
                }
            }
            completion(cookieArray)
        }
    }
}


extension ViewController {
    
    //let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    
    func get(_ id: String) -> Any? {
        let result = UserDefaults.standard.object(forKey: id)
        return result
    }
    
    func getString(_ id: String) -> String? {
        return get(id) as? String
    }
    
    func set(_ id: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: id)
    }
    
    func clear(_ id: String) {
        UserDefaults.standard.removeObject(forKey: id)
    }
}
