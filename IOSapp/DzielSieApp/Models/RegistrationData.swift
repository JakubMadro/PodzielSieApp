//
//  RegistrationData.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation

struct RegistrationData: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let phoneNumber: String?
}
