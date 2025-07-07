//
//  User.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//
import Foundation

struct User: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
    }
}
