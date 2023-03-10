//
//  ViewController.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 01/08/22.
//

import UIKit
import WebKit
import NVActivityIndicatorView
import OneSignal

class ViewController: UIViewController {
    //MARK: - VARS
    let appURL = URL(string: "https://adm.bunkerapp.com.br/app/intro.do?key=sgXRkwFYRfk")!
    var webView: WKWebView!
    var indicator = NVActivityIndicatorView(frame: .zero)
    
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
        webView = WKWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration()
        )
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

extension ViewController: WKNavigationDelegate, WKUIDelegate{
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
        
        if webView.url != nil {
            webView.getCookie { cookies in
                self.randlerCookies(cookies: cookies)
                
                if (webView.url?.description ?? "").contains("novoMenu"){
                    
                    if cookies.count != 2 {return}
                    let login = cookies[0]
                    let senha = cookies[1]
                    
                    if login.value != "true" && senha.value != "true" {
                        self.set("senha", senha.value)
                        self.set("login", login.value)
                    }
                }
            }
        }
        
        if (webView.url?.description ?? "").contains("novoMenu"){
            
            let url = webView.url!.absoluteString
            if url.contains("idU=") {
                var userID = url.substring(from: url.range(of: "idU=")!.upperBound)
                userID = userID.replacingOccurrences(of: "&log=1", with: "")
                userID = userID.removingPercentEncoding ?? userID
                userID = userID.toBase64()
                
                print("Logado\nUserID:\(userID)")
                
                self.randlerConsultaCli(userID: userID)
            }
            
        } else {
            print("URL: " + (webView.url?.description ?? ""))
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
        }
    }
    
    //MARK: - FUNCS
    
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
                self.randlerTokenOneSignal(resp)
            }
            
        }
    }
    
    func randlerTokenOneSignal(_ cli: ConsultaCli){
        
        guard let deviceState = OneSignal.getDeviceState() else {return}
        guard let token = deviceState.pushToken else {return}
        guard let userId = deviceState.userId else {return}
        
        print(cli)
        
        let param : [String: Any] = ["RD_userId": cli.rdUserID, "RD_userCompany": cli.rdUserCompany, "RD_userMail": cli.rdUserMail, "RD_userName": cli.rdUserName, "RD_userType":cli.rdUserType, "RD_TokenCelular":token, "RD_Versao":"iOS", "RD_User_Player_Id" : userId]
        
        print(param)
        
        let path = "https://adm.bunker.mk/wsjson/TokenAppPush.do"
        
        Service.shared.request(path, method: .POST , parameters: param) { (result: Result<TokenOneSignal, ErrorTypes>) in
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
