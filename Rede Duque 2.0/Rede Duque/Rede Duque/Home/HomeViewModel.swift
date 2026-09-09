import SwiftUI

enum HomeColors {
    static let brandBlue = Color(red: 0.0, green: 0.0, blue: 0.72)
    static let brandBlueDark = Color(red: 0.0, green: 0.0, blue: 0.55)
    static let accentGreen = Color(red: 0.55, green: 0.95, blue: 0.15)
    static let tileBackground = Color(red: 0.91, green: 0.90, blue: 0.97)
    static let tileForeground = Color(red: 0.05, green: 0.05, blue: 0.45)
    static let secondaryLabel = Color.white.opacity(0.75)
}

enum HomeMenuItem: String, CaseIterable, Identifiable {
    case vehicles = "Meus Veículos"
    case offers = "Minhas Ofertas"
    case profile = "Meus Dados"
    case statement = "Extrato"
    case messages = "Mensagens"
    case addresses = "Endereços"
    case contact = "Fale Conosco"
    case friends = "Meus Amigos"
    case logout = "Sair"

    var id: String { rawValue }

    /// Key inside `novoMenu.links` from APP.do.
    var novoMenuLinkKey: String? {
        switch self {
        case .vehicles: return "validacao_dados" // cadVeiculo.do
        case .offers: return "ofertas"           // ofertas.do
        case .profile: return "meus_dados"       // cadastro_V2.do
        case .statement: return "historico"      // relCompras.do
        case .messages: return "mensagens"       // historicoPush.do
        case .addresses: return "enderecos"      // regioes.do
        case .contact: return "fale_conosco"     // faleConosco.do
        case .friends: return "meus_amigos"      // manutencao.do
        case .logout: return "logout"            // intro.do (logout)
        }
    }

    var systemImage: String {
        switch self {
        case .vehicles: return "car.fill"
        case .offers: return "tag.fill"
        case .profile: return "person.crop.rectangle.fill"
        case .statement: return "doc.text.fill"
        case .messages: return "envelope.fill"
        case .addresses: return "mappin.and.ellipse"
        case .contact: return "headphones"
        case .friends: return "person.2.fill"
        case .logout: return "arrow.right.square.fill"
        }
    }
}

final class HomeViewModel: ObservableObject {
    @Published var userName: String
    @Published var firstName: String
    @Published var availableBalance: Decimal
    @Published var redeemedBalance: Decimal
    @Published var expiredBalance: Decimal
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var compras: [DadosComprasMovimento] = []
    @Published var paginacao: DadosComprasPaginacao?

    var cpf: String?
    /// Raw `idU` from login URL (query param on menu links).
    var idU: String?
    /// Bunker app client key (`key=` on menu links).
    var appKey: String
    private(set) var menuLinks: [String: String] = [:]
    var onBack: (() -> Void)?
    var onOpenURL: ((URL, String) -> Void)?
    var onLogout: ((URL) -> Void)?

    init(
        userName: String = "Cliente",
        cpf: String? = nil,
        idU: String? = nil,
        appKey: String = ViewController.bunkerAppKey,
        availableBalance: Decimal = 0,
        redeemedBalance: Decimal = 0,
        expiredBalance: Decimal = 0
    ) {
        self.userName = userName
        self.firstName = Self.extractFirstName(from: userName)
        self.cpf = cpf
        self.idU = idU
        self.appKey = appKey
        self.availableBalance = availableBalance
        self.redeemedBalance = redeemedBalance
        self.expiredBalance = expiredBalance
    }

    var greeting: String {
        "Olá, \(firstName)!"
    }

    private(set) var didResolveNameFromAPI = false

    func applyUserName(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userName = trimmed
        firstName = Self.extractFirstName(from: trimmed)
    }

    /// Prefers `primeiro_nome` from dadoscompras; falls back to the first token of `nome`.
    func applyClienteName(primeiroNome: String?, nome: String) {
        let preferred = (primeiroNome ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let full = nome.trimmingCharacters(in: .whitespacesAndNewlines)

        if !preferred.isEmpty {
            firstName = preferred
            userName = full.isEmpty ? preferred : full
        } else if !full.isEmpty {
            userName = full
            firstName = Self.extractFirstName(from: full)
        } else {
            return
        }

        didResolveNameFromAPI = true
        UserDefaults.standard.set(firstName, forKey: "userName")
    }

    static func extractFirstName(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Cliente" }
        return trimmed.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? trimmed
    }

    func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: value as NSDecimalNumber) ?? "R$ 0,00"
    }

    func loadHome(pagina: Int = 1) {
        guard let cpf = cpf, !cpf.filter(\.isNumber).isEmpty else {
            errorMessage = "CPF do cliente não encontrado para carregar o saldo."
            return
        }

        isLoading = true
        errorMessage = nil
        loadMenuLinks()

        DadosComprasAPI.fetch(cpf: cpf, pagina: pagina) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case .failure(let error):
                self.errorMessage = error.description
            case .success(let response):
                guard response.coderro == 200 else {
                    self.errorMessage = response.msgerro
                    return
                }
                if let cliente = response.cliente {
                    self.applyClienteName(primeiroNome: cliente.primeiroNome, nome: cliente.nome)
                    UserDefaults.standard.set(cliente.numCgcecpf, forKey: "cpf")
                    self.cpf = cliente.numCgcecpf
                }
                if let saldo = response.saldo {
                    self.availableBalance = Decimal(saldo.disponivel)
                    self.redeemedBalance = Decimal(saldo.resgatado)
                    self.expiredBalance = Decimal(saldo.expirado)
                }
                self.compras = response.compras ?? []
                self.paginacao = response.paginacao
            }
        }
    }

    func loadMenuLinks() {
        AppConfigAPI.fetch { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("APP.do links error:", error)
            case .success(let response):
                self.menuLinks = response.novoMenu?.links ?? [:]
                print("APP.do menu links loaded:", self.menuLinks.keys.sorted())
            }
        }
    }

    func url(for item: HomeMenuItem) -> URL? {
        guard let linkKey = item.novoMenuLinkKey,
              let raw = menuLinks[linkKey] else {
            return nil
        }
        let built = Self.buildMenuURL(from: raw, appKey: appKey, idU: idU)
        print("Menu URL [\(item.rawValue)] (\(linkKey)):", built)
        if let url = URL(string: built) {
            return url
        }
        // Fallback if URL still has unexpected characters.
        var allowed = CharacterSet.urlQueryAllowed
        allowed.insert(charactersIn: ":/?#[]@!$&'()*+,;=")
        return built.addingPercentEncoding(withAllowedCharacters: allowed).flatMap(URL.init(string:))
    }

    /// Pattern: `<path>?key=<appKey>&idU=<idU>&t=<token from APP.do>`
    static func buildMenuURL(from urlString: String, appKey: String, idU: String?) -> String {
        let base = urlString.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first
            .map(String.init) ?? urlString
        let token = queryValue(named: "t", in: urlString)

        var pairs: [(String, String)] = [
            ("key", appKey)
        ]
        if let idU = idU?.trimmingCharacters(in: .whitespacesAndNewlines), !idU.isEmpty {
            pairs.append(("idU", idU))
        }
        if let token = token, !token.isEmpty {
            pairs.append(("t", token))
        }

        let query = pairs
            .map { name, value in
                let encoded = value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? value
                return "\(name)=\(encoded)"
            }
            .joined(separator: "&")

        return base + "?" + query
    }

    static func queryValue(named name: String, in urlString: String) -> String? {
        let marker = "\(name)="
        guard let range = urlString.range(of: marker, options: .caseInsensitive) else {
            return nil
        }
        let after = urlString[range.upperBound...]
        let end = after.firstIndex(of: "&") ?? after.endIndex
        let raw = String(after[..<end])
        return raw.removingPercentEncoding ?? raw
    }

    private static var queryValueAllowed: CharacterSet {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }

    func openMenuItem(_ item: HomeMenuItem) {
        if item == .logout {
            openLogout()
            return
        }
        if let url = url(for: item) {
            onOpenURL?(url, item.rawValue)
            return
        }
        // Links may still be loading — refresh once and retry.
        AppConfigAPI.fetch { [weak self] result in
            guard let self = self else { return }
            if case .success(let response) = result {
                self.menuLinks = response.novoMenu?.links ?? [:]
            }
            if let url = self.url(for: item) {
                self.onOpenURL?(url, item.rawValue)
            } else {
                self.errorMessage = "Link indisponível para \(item.rawValue)."
            }
        }
    }

    private func openLogout() {
        if let url = url(for: .logout) {
            onLogout?(url)
            return
        }
        AppConfigAPI.fetch { [weak self] result in
            guard let self = self else { return }
            if case .success(let response) = result {
                self.menuLinks = response.novoMenu?.links ?? [:]
            }
            if let url = self.url(for: .logout) {
                self.onLogout?(url)
            } else {
                self.errorMessage = "Link de logout indisponível."
            }
        }
    }
}
