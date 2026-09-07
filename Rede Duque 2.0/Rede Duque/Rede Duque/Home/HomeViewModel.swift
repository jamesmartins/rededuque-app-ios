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
    @Published var availableBalance: Decimal
    @Published var redeemedBalance: Decimal
    @Published var expiredBalance: Decimal

    var onBack: (() -> Void)?
    var onGenerateToken: (() -> Void)?
    var onMenuItem: ((HomeMenuItem) -> Void)?
    var onRedeemed: (() -> Void)?
    var onExpired: (() -> Void)?

    init(
        userName: String = "Cliente",
        availableBalance: Decimal = 500,
        redeemedBalance: Decimal = Decimal(string: "95.99") ?? 95.99,
        expiredBalance: Decimal = Decimal(string: "1499.31") ?? 1499.31
    ) {
        self.userName = userName
        self.availableBalance = availableBalance
        self.redeemedBalance = redeemedBalance
        self.expiredBalance = expiredBalance
    }

    var greeting: String {
        let first = userName.split(separator: " ").first.map(String.init) ?? userName
        return "Olá, \(first)!"
    }

    func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: value as NSDecimalNumber) ?? "R$ 0,00"
    }
}
