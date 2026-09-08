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
    var onBack: (() -> Void)?
    var onGenerateToken: (() -> Void)?
    var onMenuItem: ((HomeMenuItem) -> Void)?
    var onRedeemed: (() -> Void)?
    var onExpired: (() -> Void)?

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

    func applyUserName(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userName = trimmed
        firstName = Self.extractFirstName(from: trimmed)
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
                    let preferred = (cliente.primeiroNome ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let full = cliente.nome.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.applyUserName(preferred.isEmpty ? full : preferred)
                    UserDefaults.standard.set(cliente.numCgcecpf, forKey: "cpf")
                    UserDefaults.standard.set(self.firstName, forKey: "userName")
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
}
