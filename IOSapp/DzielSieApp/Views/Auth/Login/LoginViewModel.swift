import Foundation
import Combine

class LoginViewModel: ObservableObject {
    // MARK: - Properties
    private let appState: AppState
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Init
    init(
        appState: AppState,
        networkService: NetworkServiceProtocol = NetworkService(),
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.appState = appState
        self.networkService = networkService
        self.authService = authService
    }
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Login Logic
    func login() {
        guard isFormValid else {
            error = "Wypełnij poprawnie wszystkie pola"
            return
        }
        
        isLoading = true
        error = nil
        
        networkService.request(.login(email: email, password: password))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] (response: LoginResponse) in
                self?.handleSuccess(response)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Handlers
    private func handleSuccess(_ response: LoginResponse) {
        authService.saveAuthData(
            token: response.token,
            refreshToken: response.refreshToken,
            user: response.user
        )
        appState.isAuthenticated = true
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Response Models
extension LoginViewModel {
    struct LoginResponse: Codable {
        let success: Bool
        let message: String?
        let token: String?
        let refreshToken: String?
        let user: User?
    }
}
