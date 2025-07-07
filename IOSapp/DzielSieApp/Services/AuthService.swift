//
//  AuthService.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

/// Protokół definiujący interfejs serwisu autoryzacji
/// Pozwala na dependency injection i łatwe testowanie
protocol AuthServiceProtocol {
    /// Zapisuje dane autoryzacji do pamięci lokalnej
    func saveAuthData(token: String?, refreshToken: String?, user: User?)
    
    /// Wysyła żądanie resetowania hasła
    func forgotPassword(email: String) -> AnyPublisher<ForgotPasswordResponse, Error>
    
    /// Resetuje hasło użytkownika za pomocą tokenu
    func resetPassword(token: String, newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error>
}

/// Serwis zarządzający autoryzacją użytkownika
/// final - nie może być dziedziczona
final class AuthService: AuthServiceProtocol {
    /// Singleton - jedna instancja na całą aplikację
    static let shared = AuthService()
    
    /// Zależność do serwisu sieciowego
    private let networkService: NetworkServiceProtocol
    
    /// Prywatny inicjalizator - wymusza użycie singletona
    /// - Parameter networkService: Serwis sieciowy (może być mockowany w testach)
    private init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    /// Zapisuje dane autoryzacji do UserDefaults i aktualizuje stan aplikacji
    /// - Parameters:
    ///   - token: Token JWT do autoryzacji
    ///   - refreshToken: Token do odświeżania sesji
    ///   - user: Dane użytkownika
    func saveAuthData(token: String?, refreshToken: String?, user: User?) {
        // Zapisz tokeny w UserDefaults
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        
        // Zakoduj i zapisz dane użytkownika
        if let user = user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "userData")
        }
        
        // Zaktualizuj globalny stan aplikacji
        AppState.shared.currentUser = user
        AppState.shared.isAuthenticated = true
    }
    
    /// Wysyła żądanie resetowania hasła na podany email
    /// - Parameter email: Adres email użytkownika
    /// - Returns: Publisher z odpowiedzią lub błędem
    func forgotPassword(email: String) -> AnyPublisher<ForgotPasswordResponse, Error> {
        return networkService.request(.forgotPassword(email: email))
    }
    
    /// Resetuje hasło użytkownika za pomocą tokenu z emaila
    /// - Parameters:
    ///   - token: Token resetowania z emaila
    ///   - newPassword: Nowe hasło
    ///   - confirmPassword: Potwierdzenie nowego hasła
    /// - Returns: Publisher z odpowiedzią lub błędem
    func resetPassword(token: String, newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error> {
        return networkService.request(.resetPassword(token: token, newPassword: newPassword, confirmPassword: confirmPassword))
    }
}

