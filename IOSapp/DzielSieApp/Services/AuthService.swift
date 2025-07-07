//
//  AuthService.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
    func saveAuthData(token: String?, refreshToken: String?, user: User?)
    func forgotPassword(email: String) -> AnyPublisher<ForgotPasswordResponse, Error>
    func resetPassword(token: String, newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error>
}

final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    private let networkService: NetworkServiceProtocol
    
    private init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func saveAuthData(token: String?, refreshToken: String?, user: User?) {
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        
        if let user = user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "userData")
        }
        
        // Aktualizuj stan w AppState
        AppState.shared.currentUser = user
        AppState.shared.isAuthenticated = true
    }
    
    func forgotPassword(email: String) -> AnyPublisher<ForgotPasswordResponse, Error> {
        return networkService.request(.forgotPassword(email: email))
    }
    
    func resetPassword(token: String, newPassword: String, confirmPassword: String) -> AnyPublisher<ResetPasswordResponse, Error> {
        return networkService.request(.resetPassword(token: token, newPassword: newPassword, confirmPassword: confirmPassword))
    }
}

