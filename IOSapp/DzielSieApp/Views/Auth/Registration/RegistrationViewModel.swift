//
//  RegistrationViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

class RegistrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var phoneNumber = ""
    @Published var isLoading = false
    @Published var isRegistered = false
    @Published var error: String?
    @Published var hasAgreedToTerms = false
    
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.networkService = networkService
        self.authService = authService
    }
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        hasAgreedToTerms
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Registration Logic
    func register() {
        // Dodatkowe, bardziej szczegółowe sprawdzenia
        guard isFormValid else {
            error = "Proszę wypełnić wszystkie wymagane pola"
            return
        }
        
        // Sprawdzenie siły hasła
        guard password.count >= 8 else {
            error = "Hasło musi mieć co najmniej 8 znaków"
            return
        }
        
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
            error = "Hasło musi zawierać co najmniej jedną cyfrę"
            return
        }
        
        isLoading = true
        error = nil
        
        let registrationData = RegistrationData(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
        )
        
        networkService.request(.register(user: registrationData))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] (response: RegistrationResponse) in
                self?.handleSuccess(response)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Handlers
    private func handleSuccess(_ response: RegistrationResponse) {
        authService.saveAuthData(
            token: response.token,
            refreshToken: response.refreshToken,
            user: response.user
        )
        isRegistered = true
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            print("API Error: \(apiError.localizedDescription)") // Dodaj logging
            self.error = apiError.localizedDescription
        } else {
            print("Unknown Error: \(error.localizedDescription)") // Dodaj logging
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}

