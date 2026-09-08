import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    private let menuItems = HomeMenuItem.allCases

    var body: some View {
        ZStack(alignment: .top) {
            HomeColors.brandBlue.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                header
                balanceSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                summaryRow
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                generateTokenButton
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 22)

                menuSheet
            }

            if viewModel.isLoading {
                Color.black.opacity(0.25).edgesIgnoringSafeArea(.all)
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button(action: { viewModel.onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(HomeColors.accentGreen)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text("Navegação")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(90))
                Text("Rede Duque")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 56)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Olá, \(viewModel.firstName)!")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(HomeColors.accentGreen)

            Text("Saldo disponível")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(HomeColors.secondaryLabel)

            Text(viewModel.formattedCurrency(viewModel.availableBalance))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(HomeColors.accentGreen)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Resgatado",
                value: viewModel.formattedCurrency(viewModel.redeemedBalance)
            )
            summaryCard(
                title: "Expirado",
                value: viewModel.formattedCurrency(viewModel.expiredBalance)
            )
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeColors.brandBlueDark.opacity(0.55))
        .cornerRadius(10)
    }

    private var generateTokenButton: some View {
        HStack(spacing: 10) {
            Image(systemName: "qrcode")
                .font(.system(size: 18, weight: .semibold))
            Text("Gerar Token")
                .font(.system(size: 17, weight: .bold))
        }
        .foregroundColor(HomeColors.tileForeground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(10)
    }

    private var menuSheet: some View {
        VStack(spacing: 0) {
            ScrollView {
                menuGrid
                    .padding(.horizontal, 18)
                    .padding(.top, 22)
                    .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color.white
                .cornerRadius(28, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private var menuGrid: some View {
        let rows = stride(from: 0, to: menuItems.count, by: 2).map { start -> [HomeMenuItem?] in
            let first = menuItems[start]
            let second: HomeMenuItem? = start + 1 < menuItems.count ? menuItems[start + 1] : nil
            return [first, second]
        }

        return VStack(spacing: 14) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 14) {
                    menuTile(row[0]!)
                    if let second = row[1] {
                        menuTile(second)
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                    }
                }
            }
        }
    }

    private func menuTile(_ item: HomeMenuItem) -> some View {
        Button(action: { viewModel.openMenuItem(item) }) {
            VStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(HomeColors.tileForeground)
                Text(item.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HomeColors.tileForeground)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(HomeColors.tileBackground)
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: HomeViewModel(userName: "Diogo"))
    }
}
#endif

/// UIKit spinner wrapper for iOS 13 compatibility.
private struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}