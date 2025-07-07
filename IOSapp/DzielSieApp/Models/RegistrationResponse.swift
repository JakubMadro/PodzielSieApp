//
//  RegistrationResponse.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation

struct RegistrationResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let refreshToken: String?
    let user: User?
}
