import Foundation
import Combine

/// ViewModel zarządzający logiką logowania użytkownika
/// ObservableObject pozwala na automatyczne odświeżanie UI przy zmianach
class LoginViewModel: ObservableObject {
    // MARK: - Properties
    /// Referencja do globalnego stanu aplikacji
    private let appState: AppState
    
    /// Serwis sieciowy do komunikacji z API
    private let networkService: NetworkServiceProtocol
    
    /// Serwis autoryzacji do zapisywania tokenów
    private let authService: AuthServiceProtocol
    
    // MARK: - Published Properties (obserwowalne przez UI)
    /// Email wprowadzony przez użytkownika
    @Published var email = ""
    
    /// Hasło wprowadzone przez użytkownika
    @Published var password = ""
    
    /// Czy logowanie jest w trakcie
    @Published var isLoading = false
    
    /// Komunikat błędu do wyświetlenia
    @Published var error: String?
    
    // MARK: - Init
    /// Inicjalizator z możliwością wstrzyknięcia zależności (dla testów)
    /// - Parameters:
    ///   - appState: Stan aplikacji
    ///   - networkService: Serwis sieciowy (domyślnie NetworkService)
    ///   - authService: Serwis autoryzacji (domyślnie AuthService.shared)
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
    /// Sprawdza czy formularz jest poprawnie wypełniony
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    /// Waliduje format adresu email za pomocą regex
    /// - Parameter email: Adres email do sprawdzenia
    /// - Returns: true jeśli email ma poprawny format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Login Logic
    /// Główna funkcja logowania - waliduje dane i wysyła zapytanie do API
    func login() {
        // Sprawdź walidację formularza
        guard isFormValid else {
            error = "Wypełnij poprawnie wszystkie pola"
            return
        }
        
        // Rozpocznij ładowanie i wyczyść poprzednie błędy
        isLoading = true
        error = nil
        
        // Wykonaj zapytanie logowania
        networkService.request(.login(email: email, password: password))
            .receive(on: DispatchQueue.main)  // Przenieś na główny wątek dla UI
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] (response: LoginResponse) in
                self?.handleSuccess(response)
            }
            .store(in: &cancellables)  // Przechowaj subscription
    }
    
    // MARK: - Handlers
    /// Obsługuje pomyslne logowanie - zapisuje tokeny i aktualizuje stan
    /// - Parameter response: Odpowiedź z API zawierająca tokeny i dane użytkownika
    private func handleSuccess(_ response: LoginResponse) {
        // Zapisz dane autoryzacji
        authService.saveAuthData(
            token: response.token,
            refreshToken: response.refreshToken,
            user: response.user
        )
        // Zaktualizuj stan aplikacji - spowoduje przekierowanie do głównego ekranu
        appState.isAuthenticated = true
    }
    
    /// Obsługuje błędy logowania i wyświetla odpowiedni komunikat
    /// - Parameter error: Błąd z API lub sieciowy
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
    
    /// Zestaw subscriptionów Combine - automatycznie anulowane przy dealokacji
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Response Models
extension LoginViewModel {
    /// Model odpowiedzi z API po logowaniu
    struct LoginResponse: Codable {
        /// Czy operacja się powiodła
        let success: Bool
        
        /// Opcjonalny komunikat z serwera
        let message: String?
        
        /// Token JWT do autoryzacji
        let token: String?
        
        /// Token do odświeżania sesji
        let refreshToken: String?
        
        /// Dane zalogowanego użytkownika
        let user: User?
    }
}
