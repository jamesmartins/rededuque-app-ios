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
        case .offers: return "ofertas"
        case .profile: return "meus_dados"
        case .statement: return "historico" // relCompras.do — confirm vs cashback
        case .messages: return "mensagens"
        case .addresses: return "enderecos" // regioes.do — confirm vs enderecos_duque
        case .contact: return "fale_conosco"
        case .friends: return "meus_amigos"
        case .logout: return nil
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
    private(set) var menuLinks: [String: String] = [:]
    var onBack: (() -> Void)?
    var onMenuItem: ((HomeMenuItem) -> Void)?
    var onOpenURL: ((URL, String) -> Void)?

    init(
        userName: String = "Cliente",
        cpf: String? = nil,
        availableBalance: Decimal = 0,
        redeemedBalance: Decimal = 0,
        expiredBalance: Decimal = 0
    ) {
        self.userName = userName
        self.firstName = Self.extractFirstName(from: userName)
        self.cpf = cpf
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
            if case .success(let response) = result {
                self.menuLinks = response.novoMenu?.links ?? [:]
            }
        }
    }

    func url(for item: HomeMenuItem) -> URL? {
        guard let key = item.novoMenuLinkKey,
              let raw = menuLinks[key] else {
            return nil
        }
        if let url = URL(string: raw) {
            return url
        }
        // APP.do tokens may include non-ASCII (e.g. £).
        var allowed = CharacterSet.urlQueryAllowed
        allowed.insert(charactersIn: ":/?#[]@!$&'()*+,;=")
        return raw.addingPercentEncoding(withAllowedCharacters: allowed).flatMap(URL.init(string:))
    }

    func openMenuItem(_ item: HomeMenuItem) {
        if item == .logout {
            onMenuItem?(item)
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
}
