//
//  PasswordResetModels.swift
//  DzielSieApp
//
//  Created by Claude on 06/07/2025.
//

import Foundation

// MARK: - Forgot Password Response
struct ForgotPasswordResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Reset Password Response
struct ResetPasswordResponse: Codable {
    let success: Bool
    let message: String
}