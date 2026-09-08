import UIKit
import SwiftUI
import Combine

final class HomeViewController: UIHostingController<HomeView> {
    let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
        super.init(rootView: HomeView(viewModel: viewModel))
        bindViewModel()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0.72, alpha: 1)
    }

    private func bindViewModel() {
        // UIHostingController on older iOS can miss @Published updates; rebind rootView.
        let refreshTriggers: [AnyPublisher<Void, Never>] = [
            viewModel.$firstName.map { _ in () }.eraseToAnyPublisher(),
            viewModel.$userName.map { _ in () }.eraseToAnyPublisher(),
            viewModel.$availableBalance.map { _ in () }.eraseToAnyPublisher(),
            viewModel.$redeemedBalance.map { _ in () }.eraseToAnyPublisher(),
            viewModel.$expiredBalance.map { _ in () }.eraseToAnyPublisher(),
            viewModel.$isLoading.map { _ in () }.eraseToAnyPublisher(),
            viewModel.$errorMessage.map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(refreshTriggers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.rootView = HomeView(viewModel: self.viewModel)
            }
            .store(in: &cancellables)
    }
}
